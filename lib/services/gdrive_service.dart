import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'log_service.dart';
import 'settings_service.dart';

/// Service for downloading files from Google Drive public folders
class GDriveService extends ChangeNotifier {
  static final GDriveService _instance = GDriveService._internal();
  factory GDriveService() => _instance;
  GDriveService._internal();

  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();

  final Map<String, GDriveDownload> _downloads = {};
  List<GDriveFile> _files = [];
  bool _isLoading = false;
  String? _error;

  Map<String, GDriveDownload> get downloads => Map.unmodifiable(_downloads);
  List<GDriveFile> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Epstein Files Google Drive folder
  static const String epsteinFilesFolderId = '18tIY9QEGUZe0q_AFAxoPnnVBCWbqHm2p';

  /// Fetch file list from a public Google Drive folder
  /// Note: This requires the folder to be publicly accessible
  Future<List<GDriveFile>> fetchFolderContents(String folderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use Google Drive API v3 to list files in public folder
      // This works for folders shared with "Anyone with the link"
      final url = 'https://www.googleapis.com/drive/v3/files'
          '?q=%27$folderId%27+in+parents'
          '&fields=files(id,name,mimeType,size,modifiedTime)'
          '&pageSize=1000';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filesList = data['files'] as List<dynamic>? ?? [];

        _files = filesList.map((f) => GDriveFile(
          id: f['id'] ?? '',
          name: f['name'] ?? 'Unknown',
          mimeType: f['mimeType'] ?? '',
          size: int.tryParse(f['size']?.toString() ?? '0') ?? 0,
          modifiedTime: f['modifiedTime'] ?? '',
        )).toList();

        _log.info('GDrive', 'Fetched ${_files.length} files from folder');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Folder requires auth or API key - fall back to manual download
        _error = 'This folder requires authentication. Please use the "Open in Browser" button to access files.';
        _log.warning('GDrive', 'Folder requires auth: ${response.statusCode}');
      } else {
        _error = 'Failed to fetch folder: HTTP ${response.statusCode}';
        _log.error('GDrive', _error!);
      }
    } catch (e) {
      _error = 'Failed to fetch folder: $e';
      _log.error('GDrive', _error!);
    }

    _isLoading = false;
    notifyListeners();
    return _files;
  }

  /// Download a file from Google Drive by ID
  Future<bool> downloadFile(GDriveFile file) async {
    if (_downloads.containsKey(file.id) &&
        _downloads[file.id]!.status == GDriveDownloadStatus.downloading) {
      _log.warning('GDrive', 'File already downloading: ${file.name}');
      return false;
    }

    final downloadDir = _settings.settings.downloadLocation;
    final gdriveDir = path.join(downloadDir, 'GDrive_Archives');
    await Directory(gdriveDir).create(recursive: true);

    final filePath = path.join(gdriveDir, _sanitizeFilename(file.name));

    // Check if file already exists
    if (File(filePath).existsSync()) {
      _log.info('GDrive', 'File already exists: ${file.name}');
      _downloads[file.id] = GDriveDownload(
        fileId: file.id,
        fileName: file.name,
        status: GDriveDownloadStatus.completed,
        bytesReceived: file.size,
        totalBytes: file.size,
        filePath: filePath,
      );
      notifyListeners();
      return true;
    }

    _downloads[file.id] = GDriveDownload(
      fileId: file.id,
      fileName: file.name,
      status: GDriveDownloadStatus.downloading,
      bytesReceived: 0,
      totalBytes: file.size,
    );
    notifyListeners();

    _log.info('GDrive', 'Starting download: ${file.name}');

    http.Client? client;
    IOSink? sink;

    try {
      // Google Drive direct download URL
      // For large files, may need to handle the confirmation page
      var downloadUrl = 'https://drive.google.com/uc?export=download&id=${file.id}';

      client = http.Client();
      var request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';

      var response = await client.send(request);

      // Handle Google Drive virus scan confirmation for large files
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          // Need to get confirmation token for large files
          final body = await response.stream.bytesToString();
          final confirmMatch = RegExp(r'confirm=([^&"]+)').firstMatch(body);
          if (confirmMatch != null) {
            final confirm = confirmMatch.group(1);
            downloadUrl = 'https://drive.google.com/uc?export=download&confirm=$confirm&id=${file.id}';
            client.close();
            client = http.Client();
            request = http.Request('GET', Uri.parse(downloadUrl));
            request.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';
            response = await client.send(request);
          }
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? file.size;
      var receivedBytes = 0;
      final tempFile = File('$filePath.tmp');
      sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        _downloads[file.id] = GDriveDownload(
          fileId: file.id,
          fileName: file.name,
          status: GDriveDownloadStatus.downloading,
          bytesReceived: receivedBytes,
          totalBytes: totalBytes > 0 ? totalBytes : file.size,
        );
        notifyListeners();
      }

      await sink.close();
      sink = null;

      // Rename temp file to final name
      await tempFile.rename(filePath);

      _downloads[file.id] = GDriveDownload(
        fileId: file.id,
        fileName: file.name,
        status: GDriveDownloadStatus.completed,
        bytesReceived: receivedBytes,
        totalBytes: receivedBytes,
        filePath: filePath,
      );
      notifyListeners();

      _log.info('GDrive', 'Completed: ${file.name}');
      return true;
    } catch (e) {
      _log.error('GDrive', 'Failed: ${file.name} - $e');
      _downloads[file.id] = GDriveDownload(
        fileId: file.id,
        fileName: file.name,
        status: GDriveDownloadStatus.failed,
        bytesReceived: 0,
        totalBytes: file.size,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
    }
  }

  /// Cancel a download
  void cancelDownload(String fileId) {
    if (_downloads.containsKey(fileId)) {
      _downloads[fileId] = GDriveDownload(
        fileId: fileId,
        fileName: _downloads[fileId]!.fileName,
        status: GDriveDownloadStatus.cancelled,
        bytesReceived: 0,
        totalBytes: 0,
      );
      notifyListeners();
    }
  }

  /// Clear completed/failed downloads
  void clearCompleted() {
    _downloads.removeWhere((_, d) =>
      d.status == GDriveDownloadStatus.completed ||
      d.status == GDriveDownloadStatus.failed ||
      d.status == GDriveDownloadStatus.cancelled
    );
    notifyListeners();
  }

  /// Open Google Drive folder in browser
  Future<void> openFolderInBrowser(String folderId) async {
    final url = 'https://drive.google.com/drive/folders/$folderId';
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
      _log.info('GDrive', 'Opened folder in browser: $folderId');
    } catch (e) {
      _log.error('GDrive', 'Failed to open browser: $e');
    }
  }

  String _sanitizeFilename(String filename) {
    // Remove invalid characters
    var sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Limit length
    if (sanitized.length > 200) {
      final ext = path.extension(sanitized);
      sanitized = '${sanitized.substring(0, 200 - ext.length)}$ext';
    }
    return sanitized;
  }
}

/// Represents a file in Google Drive
class GDriveFile {
  final String id;
  final String name;
  final String mimeType;
  final int size;
  final String modifiedTime;

  GDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.modifiedTime,
  });

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Status of a Google Drive download
enum GDriveDownloadStatus {
  downloading,
  completed,
  failed,
  cancelled,
}

/// Represents a download from Google Drive
class GDriveDownload {
  final String fileId;
  final String fileName;
  final GDriveDownloadStatus status;
  final int bytesReceived;
  final int totalBytes;
  final String? filePath;
  final String? error;

  GDriveDownload({
    required this.fileId,
    required this.fileName,
    required this.status,
    required this.bytesReceived,
    required this.totalBytes,
    this.filePath,
    this.error,
  });

  double get progress => totalBytes > 0 ? bytesReceived / totalBytes : 0;
}
