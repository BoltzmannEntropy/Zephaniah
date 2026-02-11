import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'log_service.dart';
import 'settings_service.dart';
import 'library_service.dart';

/// Service for generating and caching thumbnails
class ThumbnailService {
  static final ThumbnailService _instance = ThumbnailService._internal();
  factory ThumbnailService() => _instance;
  ThumbnailService._internal();

  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();

  static const int thumbnailSize = 200;

  /// Get the thumbnails cache directory
  String get cacheDir =>
      '${_settings.settings.downloadLocation}/DOJ_Archives/.thumbnails';

  /// Initialize the thumbnail cache directory
  Future<void> initialize() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Generate a cache key for a file
  String _getCacheKey(String filePath) {
    final bytes = utf8.encode(filePath);
    final hash = md5.convert(bytes);
    return hash.toString();
  }

  /// Get thumbnail path for a file (creates if doesn't exist)
  Future<String?> getThumbnail(LibraryFile file) async {
    // Check if thumbnail already exists
    final cacheKey = _getCacheKey(file.path);
    final thumbnailPath = '$cacheDir/$cacheKey.jpg';

    if (await File(thumbnailPath).exists()) {
      return thumbnailPath;
    }

    // Generate thumbnail based on file type
    try {
      if (file.isImage) {
        return await _generateImageThumbnail(file.path, thumbnailPath);
      } else if (file.isVideo) {
        return await _generateVideoThumbnail(file.path, thumbnailPath);
      } else if (file.isPdf) {
        return await _generatePdfThumbnail(file.path, thumbnailPath);
      }
    } catch (e) {
      _log.error('Thumbnail', 'Failed to generate thumbnail for ${file.filename}: $e');
    }

    return null;
  }

  /// Generate thumbnail for an image using sips (macOS)
  Future<String?> _generateImageThumbnail(String sourcePath, String destPath) async {
    if (!Platform.isMacOS) return null;

    try {
      // Use sips to resize image
      final result = await Process.run('sips', [
        '-Z', '$thumbnailSize',
        '-s', 'format', 'jpeg',
        '-s', 'formatOptions', '80',
        sourcePath,
        '--out', destPath,
      ]);

      if (result.exitCode == 0 && await File(destPath).exists()) {
        return destPath;
      }
    } catch (e) {
      _log.error('Thumbnail', 'sips failed: $e');
    }
    return null;
  }

  /// Generate thumbnail for a video using ffmpeg
  Future<String?> _generateVideoThumbnail(String sourcePath, String destPath) async {
    // Check if ffmpeg is available
    try {
      final which = await Process.run('which', ['ffmpeg']);
      if (which.exitCode != 0) {
        // ffmpeg not installed, try using qlmanage as fallback
        return await _generateQuickLookThumbnail(sourcePath, destPath);
      }

      // Extract frame at 1 second
      final result = await Process.run('ffmpeg', [
        '-y',
        '-i', sourcePath,
        '-ss', '00:00:01',
        '-vframes', '1',
        '-vf', 'scale=$thumbnailSize:-1',
        '-q:v', '3',
        destPath,
      ]);

      if (result.exitCode == 0 && await File(destPath).exists()) {
        return destPath;
      }
    } catch (e) {
      _log.error('Thumbnail', 'ffmpeg failed: $e');
    }

    // Fallback to Quick Look
    return await _generateQuickLookThumbnail(sourcePath, destPath);
  }

  /// Generate thumbnail for a PDF using Quick Look
  Future<String?> _generatePdfThumbnail(String sourcePath, String destPath) async {
    return await _generateQuickLookThumbnail(sourcePath, destPath);
  }

  /// Generate thumbnail using macOS Quick Look (qlmanage)
  Future<String?> _generateQuickLookThumbnail(String sourcePath, String destPath) async {
    if (!Platform.isMacOS) return null;

    Directory? tempDir;
    try {
      tempDir = Directory.systemTemp.createTempSync('ql_thumb_');

      final result = await Process.run('qlmanage', [
        '-t',
        '-s', '$thumbnailSize',
        '-o', tempDir.path,
        sourcePath,
      ]);

      if (result.exitCode == 0) {
        // qlmanage creates files with .png extension
        final basename = path.basenameWithoutExtension(sourcePath);
        final qlFile = File('${tempDir.path}/$basename.png');

        if (await qlFile.exists()) {
          // Convert to JPEG using sips
          await Process.run('sips', [
            '-s', 'format', 'jpeg',
            '-s', 'formatOptions', '80',
            qlFile.path,
            '--out', destPath,
          ]);

          if (await File(destPath).exists()) {
            return destPath;
          }
        }
      }
    } catch (e) {
      _log.error('Thumbnail', 'qlmanage failed: $e');
    } finally {
      // Always cleanup temp directory
      try {
        if (tempDir != null && await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
    return null;
  }

  /// Generate thumbnails for a list of files in the background
  Future<void> generateThumbnailsBatch(List<LibraryFile> files, {
    void Function(int completed, int total)? onProgress,
  }) async {
    await initialize();

    int completed = 0;
    for (final file in files) {
      if (file.isImage || file.isVideo || file.isPdf) {
        file.thumbnailPath = await getThumbnail(file);
        completed++;
        onProgress?.call(completed, files.length);
      }
    }
  }

  /// Clear all cached thumbnails
  Future<void> clearCache() async {
    try {
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      _log.info('Thumbnail', 'Cache cleared');
    } catch (e) {
      _log.error('Thumbnail', 'Failed to clear cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    int totalSize = 0;
    try {
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      _log.error('Thumbnail', 'Failed to calculate cache size: $e');
    }
    return totalSize;
  }
}
