import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'log_service.dart';
import 'settings_service.dart';

/// Service for scanning and managing downloaded archive files
class LibraryService extends ChangeNotifier {
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();

  final List<LibraryFile> _files = [];
  final Map<String, DatasetInfo> _datasets = {};
  bool _isScanning = false;
  String? _currentDataset;
  String? _currentFileType;
  String _searchQuery = '';

  List<LibraryFile> get files => _getFilteredFiles();
  Map<String, DatasetInfo> get datasets => Map.unmodifiable(_datasets);
  bool get isScanning => _isScanning;
  String? get currentDataset => _currentDataset;
  String? get currentFileType => _currentFileType;

  /// Get the root archives directory
  String get archivesDir =>
      '${_settings.settings.downloadLocation}/DOJ_Archives';

  /// Scan all downloaded archives for media files
  Future<void> scanLibrary() async {
    if (_isScanning) return;

    _isScanning = true;
    _files.clear();
    _datasets.clear();
    notifyListeners();

    try {
      final rootDir = Directory(archivesDir);
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
        _log.info('Library', 'Created archives directory: $archivesDir');
        _isScanning = false;
        notifyListeners();
        return;
      }

      _log.info('Library', 'Scanning archives directory: $archivesDir');

      // Scan each dataset directory
      await for (final entity in rootDir.list()) {
        if (entity is Directory) {
          final datasetName = path.basename(entity.path);
          await _scanDatasetDirectory(entity, datasetName);
        }
      }

      // Also scan root for any loose files
      await _scanDirectory(rootDir, 'Unsorted');

      _log.info('Library',
          'Scan complete: ${_files.length} files in ${_datasets.length} datasets');
    } catch (e) {
      _log.error('Library', 'Scan failed: $e');
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<void> _scanDatasetDirectory(Directory dir, String datasetName) async {
    int fileCount = 0;
    int totalSize = 0;

    await _scanDirectory(dir, datasetName, (file, size) {
      fileCount++;
      totalSize += size;
    });

    if (fileCount > 0) {
      _datasets[datasetName] = DatasetInfo(
        name: datasetName,
        path: dir.path,
        fileCount: fileCount,
        totalSize: totalSize,
      );
    }
  }

  Future<void> _scanDirectory(
    Directory dir,
    String datasetName,
    [void Function(File, int)? onFile,]
  ) async {
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          final fileType = _getFileType(ext);

          if (fileType != null) {
            final stat = await entity.stat();
            final file = LibraryFile(
              path: entity.path,
              filename: path.basename(entity.path),
              dataset: datasetName,
              fileType: fileType,
              size: stat.size,
              modifiedAt: stat.modified,
            );
            _files.add(file);
            onFile?.call(entity, stat.size);
          }
        }
      }
    } catch (e) {
      _log.error('Library', 'Error scanning ${dir.path}: $e');
    }
  }

  String? _getFileType(String ext) {
    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif']
        .contains(ext)) {
      return 'image';
    }
    // Videos
    if (['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v']
        .contains(ext)) {
      return 'video';
    }
    // Audio
    if (['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma']
        .contains(ext)) {
      return 'audio';
    }
    // Documents
    if (['.pdf'].contains(ext)) {
      return 'pdf';
    }
    if (['.doc', '.docx'].contains(ext)) {
      return 'document';
    }
    if (['.xls', '.xlsx'].contains(ext)) {
      return 'spreadsheet';
    }
    if (['.txt', '.rtf', '.md'].contains(ext)) {
      return 'text';
    }
    return null; // Skip unknown types
  }

  /// Filter files by dataset
  void setDatasetFilter(String? dataset) {
    _currentDataset = dataset;
    notifyListeners();
  }

  /// Filter files by type
  void setTypeFilter(String? fileType) {
    _currentFileType = fileType;
    notifyListeners();
  }

  /// Search files by name
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _currentDataset = null;
    _currentFileType = null;
    _searchQuery = '';
    notifyListeners();
  }

  List<LibraryFile> _getFilteredFiles() {
    var filtered = _files;

    if (_currentDataset != null) {
      filtered = filtered.where((f) => f.dataset == _currentDataset).toList();
    }

    if (_currentFileType != null) {
      filtered = filtered.where((f) => f.fileType == _currentFileType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) => f.filename.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Sort by modified date, newest first
    filtered.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return filtered;
  }

  /// Get file counts by type
  Map<String, int> getTypeCounts() {
    final counts = <String, int>{};
    for (final file in _files) {
      counts[file.fileType] = (counts[file.fileType] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total library stats
  LibraryStats getStats() {
    int totalSize = 0;
    for (final file in _files) {
      totalSize += file.size;
    }
    return LibraryStats(
      totalFiles: _files.length,
      totalSize: totalSize,
      datasetCount: _datasets.length,
      typeCounts: getTypeCounts(),
    );
  }

  /// Open file with system default application
  Future<void> openFile(LibraryFile file) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('start', ['', file.path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      }
      _log.info('Library', 'Opened file: ${file.filename}');
    } catch (e) {
      _log.error('Library', 'Failed to open file: $e');
    }
  }

  /// Open file's folder in finder
  Future<void> revealInFinder(LibraryFile file) async {
    try {
      final folder = path.dirname(file.path);
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', file.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', file.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folder]);
      }
    } catch (e) {
      _log.error('Library', 'Failed to reveal in finder: $e');
    }
  }

  /// Delete a file from the library
  Future<bool> deleteFile(LibraryFile file) async {
    try {
      final f = File(file.path);
      if (await f.exists()) {
        await f.delete();
      }
      _files.remove(file);
      notifyListeners();
      _log.info('Library', 'Deleted file: ${file.filename}');
      return true;
    } catch (e) {
      _log.error('Library', 'Failed to delete file: $e');
      return false;
    }
  }
}

/// Represents a file in the library
class LibraryFile {
  final String path;
  final String filename;
  final String dataset;
  final String fileType;
  final int size;
  final DateTime modifiedAt;
  String? thumbnailPath;

  LibraryFile({
    required this.path,
    required this.filename,
    required this.dataset,
    required this.fileType,
    required this.size,
    required this.modifiedAt,
    this.thumbnailPath,
  });

  String get extension {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }

  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';
  bool get isAudio => fileType == 'audio';
  bool get isPdf => fileType == 'pdf';
  bool get isDocument => fileType == 'document' || fileType == 'spreadsheet' || fileType == 'text';

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Information about a dataset directory
class DatasetInfo {
  final String name;
  final String path;
  final int fileCount;
  final int totalSize;

  DatasetInfo({
    required this.name,
    required this.path,
    required this.fileCount,
    required this.totalSize,
  });

  String get sizeFormatted {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Overall library statistics
class LibraryStats {
  final int totalFiles;
  final int totalSize;
  final int datasetCount;
  final Map<String, int> typeCounts;

  LibraryStats({
    required this.totalFiles,
    required this.totalSize,
    required this.datasetCount,
    required this.typeCounts,
  });

  String get sizeFormatted {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
