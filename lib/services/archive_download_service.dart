import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'log_service.dart';
import 'settings_service.dart';
import 'library_service.dart';

/// Status of an archive download
enum ArchiveDownloadStatus {
  queued,
  downloading,
  extracting,
  completed,
  failed,
}

/// Progress information for an archive download
class ArchiveDownloadProgress {
  final String datasetName;
  final int bytesReceived;
  final int totalBytes;
  final ArchiveDownloadStatus status;
  final String? filePath;
  final String? extractedPath;
  final String? error;
  final DateTime startedAt;
  final int extractedFiles;
  final int totalFiles;
  final String? currentFile;

  const ArchiveDownloadProgress({
    required this.datasetName,
    required this.bytesReceived,
    required this.totalBytes,
    required this.status,
    this.filePath,
    this.extractedPath,
    this.error,
    required this.startedAt,
    this.extractedFiles = 0,
    this.totalFiles = 0,
    this.currentFile,
  });

  double get progress {
    if (status == ArchiveDownloadStatus.extracting && totalFiles > 0) {
      return extractedFiles / totalFiles;
    }
    return totalBytes > 0 ? bytesReceived / totalBytes : 0;
  }

  int get progressPercent => (progress * 100).round();

  String get statusText {
    switch (status) {
      case ArchiveDownloadStatus.queued:
        return 'Queued';
      case ArchiveDownloadStatus.downloading:
        return 'Downloading...';
      case ArchiveDownloadStatus.extracting:
        return 'Extracting ($extractedFiles/$totalFiles)...';
      case ArchiveDownloadStatus.completed:
        return 'Completed';
      case ArchiveDownloadStatus.failed:
        return 'Failed';
    }
  }

  ArchiveDownloadProgress copyWith({
    String? datasetName,
    int? bytesReceived,
    int? totalBytes,
    ArchiveDownloadStatus? status,
    String? filePath,
    String? extractedPath,
    String? error,
    DateTime? startedAt,
    int? extractedFiles,
    int? totalFiles,
    String? currentFile,
  }) {
    return ArchiveDownloadProgress(
      datasetName: datasetName ?? this.datasetName,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      extractedPath: extractedPath ?? this.extractedPath,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      extractedFiles: extractedFiles ?? this.extractedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFile: currentFile ?? this.currentFile,
    );
  }
}

/// Singleton service for managing archive downloads
/// Persists state across page navigation
class ArchiveDownloadService extends ChangeNotifier {
  static final ArchiveDownloadService _instance = ArchiveDownloadService._internal();
  factory ArchiveDownloadService() => _instance;
  ArchiveDownloadService._internal();

  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();
  final LibraryService _library = LibraryService();

  final Map<String, ArchiveDownloadProgress> _downloads = {};
  final Map<String, StreamSubscription> _activeStreams = {};
  final Map<String, http.Client> _activeClients = {};

  /// Get all downloads (unmodifiable view)
  Map<String, ArchiveDownloadProgress> get downloads => Map.unmodifiable(_downloads);

  /// Get download progress for a specific dataset
  ArchiveDownloadProgress? getProgress(String datasetName) => _downloads[datasetName];

  /// Check if a download is active for a dataset
  bool isDownloading(String datasetName) {
    final progress = _downloads[datasetName];
    return progress != null &&
        (progress.status == ArchiveDownloadStatus.downloading ||
         progress.status == ArchiveDownloadStatus.extracting);
  }

  /// Check if any download is active
  bool get hasActiveDownloads => _downloads.values.any(
    (p) => p.status == ArchiveDownloadStatus.downloading ||
           p.status == ArchiveDownloadStatus.extracting,
  );

  /// Get count of active downloads
  int get activeCount => _downloads.values
      .where((p) => p.status == ArchiveDownloadStatus.downloading ||
                    p.status == ArchiveDownloadStatus.extracting)
      .length;

  /// Get count of completed downloads
  int get completedCount => _downloads.values
      .where((p) => p.status == ArchiveDownloadStatus.completed)
      .length;

  /// Start downloading an archive
  Future<void> startDownload({
    required String datasetName,
    required String url,
    required int expectedSize,
  }) async {
    // Check if already downloading
    if (isDownloading(datasetName)) {
      _log.warning('ArchiveDownload', '$datasetName is already downloading');
      return;
    }

    final downloadDir = _settings.settings.downloadLocation;
    final archivesDir = path.join(downloadDir, 'DOJ_Archives');
    await Directory(archivesDir).create(recursive: true);

    final filename = '${datasetName.replaceAll(' ', '_')}.zip';
    final filePath = path.join(archivesDir, filename);

    // Initialize progress
    _downloads[datasetName] = ArchiveDownloadProgress(
      datasetName: datasetName,
      bytesReceived: 0,
      totalBytes: expectedSize,
      status: ArchiveDownloadStatus.downloading,
      startedAt: DateTime.now(),
    );
    notifyListeners();

    _log.info('ArchiveDownload', 'Starting: $datasetName');

    http.Client? client;
    IOSink? sink;

    try {
      client = http.Client();
      _activeClients[datasetName] = client;

      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';
      request.headers['Accept'] = 'application/zip, application/octet-stream, */*';

      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? expectedSize;
      var receivedBytes = 0;
      final file = File(filePath);
      sink = file.openWrite();

      final subscription = response.stream.listen(
        (chunk) {
          sink!.add(chunk);
          receivedBytes += chunk.length;

          _downloads[datasetName] = _downloads[datasetName]!.copyWith(
            bytesReceived: receivedBytes,
            totalBytes: totalBytes,
          );
          notifyListeners();
        },
        onDone: () async {
          await sink?.close();
          sink = null;
          client?.close();
          _activeClients.remove(datasetName);
          _activeStreams.remove(datasetName);

          _downloads[datasetName] = _downloads[datasetName]!.copyWith(
            bytesReceived: receivedBytes,
            totalBytes: receivedBytes,
            filePath: filePath,
          );
          notifyListeners();

          _log.info('ArchiveDownload', 'Download completed: $datasetName, starting extraction...');

          // Start extraction
          await _extractZip(datasetName, filePath);
        },
        onError: (error) async {
          await sink?.close();
          client?.close();
          _activeClients.remove(datasetName);
          _activeStreams.remove(datasetName);

          _downloads[datasetName] = _downloads[datasetName]!.copyWith(
            status: ArchiveDownloadStatus.failed,
            error: error.toString(),
          );
          notifyListeners();

          _log.error('ArchiveDownload', 'Failed: $datasetName - $error');
        },
        cancelOnError: true,
      );

      _activeStreams[datasetName] = subscription;
    } catch (e) {
      await sink?.close();
      client?.close();
      _activeClients.remove(datasetName);

      _downloads[datasetName] = _downloads[datasetName]!.copyWith(
        status: ArchiveDownloadStatus.failed,
        error: e.toString(),
      );
      notifyListeners();

      _log.error('ArchiveDownload', 'Failed to start: $datasetName - $e');
    }
  }

  /// Extract a ZIP file to the dataset directory
  Future<void> _extractZip(String datasetName, String zipPath) async {
    final extractDir = path.join(
      path.dirname(zipPath),
      datasetName.replaceAll(' ', '_'),
    );

    try {
      _downloads[datasetName] = _downloads[datasetName]!.copyWith(
        status: ArchiveDownloadStatus.extracting,
        extractedPath: extractDir,
        extractedFiles: 0,
        totalFiles: 0,
      );
      notifyListeners();

      // Read the ZIP file
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final totalFiles = archive.files.where((f) => !f.isFile || f.size > 0).length;
      var extractedCount = 0;

      _downloads[datasetName] = _downloads[datasetName]!.copyWith(
        totalFiles: totalFiles,
      );
      notifyListeners();

      // Create extraction directory
      await Directory(extractDir).create(recursive: true);

      _log.info('ArchiveDownload', 'Extracting $totalFiles files to: $extractDir');

      // Extract files
      for (final file in archive.files) {
        final filename = file.name;

        if (file.isFile) {
          final outPath = path.join(extractDir, filename);

          // Create parent directories
          final parentDir = Directory(path.dirname(outPath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          // Write file
          final outFile = File(outPath);
          await outFile.writeAsBytes(file.content as List<int>);

          extractedCount++;

          // Update progress periodically (every 10 files or on last file)
          if (extractedCount % 10 == 0 || extractedCount == totalFiles) {
            _downloads[datasetName] = _downloads[datasetName]!.copyWith(
              extractedFiles: extractedCount,
              currentFile: filename,
            );
            notifyListeners();
          }
        } else {
          // Directory entry - create it
          final dirPath = path.join(extractDir, filename);
          await Directory(dirPath).create(recursive: true);
        }
      }

      // Delete the ZIP file after successful extraction
      try {
        await File(zipPath).delete();
        _log.info('ArchiveDownload', 'Deleted ZIP file: $zipPath');
      } catch (e) {
        _log.warning('ArchiveDownload', 'Could not delete ZIP file: $e');
      }

      _downloads[datasetName] = _downloads[datasetName]!.copyWith(
        status: ArchiveDownloadStatus.completed,
        extractedFiles: extractedCount,
        totalFiles: totalFiles,
      );
      notifyListeners();

      _log.info('ArchiveDownload', 'Extraction completed: $datasetName ($extractedCount files)');

      // Trigger library rescan to show new files
      _library.scanLibrary();

    } catch (e) {
      _downloads[datasetName] = _downloads[datasetName]!.copyWith(
        status: ArchiveDownloadStatus.failed,
        error: 'Extraction failed: $e',
      );
      notifyListeners();

      _log.error('ArchiveDownload', 'Extraction failed: $datasetName - $e');
    }
  }

  /// Cancel a download
  void cancelDownload(String datasetName) {
    final subscription = _activeStreams.remove(datasetName);
    subscription?.cancel();

    final client = _activeClients.remove(datasetName);
    client?.close();

    _downloads.remove(datasetName);
    notifyListeners();

    _log.info('ArchiveDownload', 'Cancelled: $datasetName');
  }

  /// Clear a completed or failed download from the list
  void clearDownload(String datasetName) {
    final progress = _downloads[datasetName];
    if (progress != null &&
        (progress.status == ArchiveDownloadStatus.completed ||
         progress.status == ArchiveDownloadStatus.failed)) {
      _downloads.remove(datasetName);
      notifyListeners();
    }
  }

  /// Clear all completed downloads
  void clearCompleted() {
    _downloads.removeWhere((_, p) => p.status == ArchiveDownloadStatus.completed);
    notifyListeners();
  }

  /// Retry a failed download
  Future<void> retryDownload({
    required String datasetName,
    required String url,
    required int expectedSize,
  }) async {
    _downloads.remove(datasetName);
    await startDownload(
      datasetName: datasetName,
      url: url,
      expectedSize: expectedSize,
    );
  }

  /// Get the archives directory path
  String get archivesDir =>
      path.join(_settings.settings.downloadLocation, 'DOJ_Archives');

  /// Check if a file already exists for a dataset
  Future<bool> fileExists(String datasetName) async {
    final filename = '${datasetName.replaceAll(' ', '_')}.zip';
    final filePath = path.join(archivesDir, filename);
    return File(filePath).exists();
  }

  /// Check if extracted directory exists for a dataset
  Future<bool> isExtracted(String datasetName) async {
    final dirPath = path.join(archivesDir, datasetName.replaceAll(' ', '_'));
    return Directory(dirPath).exists();
  }

  /// Delete the extracted files for a dataset
  Future<bool> deleteExtracted(String datasetName) async {
    final dirPath = path.join(archivesDir, datasetName.replaceAll(' ', '_'));
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _downloads.remove(datasetName);
        notifyListeners();
        _library.scanLibrary();
        return true;
      }
    } catch (e) {
      _log.error('ArchiveDownload', 'Failed to delete: $e');
    }
    return false;
  }

  /// Delete the ZIP file for a dataset (if extraction hasn't happened)
  Future<bool> deleteZip(String datasetName) async {
    final filename = '${datasetName.replaceAll(' ', '_')}.zip';
    final filePath = path.join(archivesDir, filename);
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _downloads.remove(datasetName);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _log.error('ArchiveDownload', 'Failed to delete ZIP: $e');
    }
    return false;
  }

  /// Get the number of files in an extracted dataset directory
  Future<int> getExtractedFileCount(String datasetName) async {
    final dirPath = path.join(archivesDir, datasetName.replaceAll(' ', '_'));
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        int count = 0;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) count++;
        }
        return count;
      }
    } catch (e) {
      _log.error('ArchiveDownload', 'Failed to count files: $e');
    }
    return 0;
  }

  /// Get dataset status summary for display in Library
  Future<DatasetExtractionStatus> getDatasetStatus(String datasetName) async {
    final isExtractedResult = await isExtracted(datasetName);
    final progress = getProgress(datasetName);

    if (progress != null) {
      if (progress.status == ArchiveDownloadStatus.downloading) {
        return DatasetExtractionStatus(
          isExtracted: false,
          isDownloading: true,
          progress: progress.progress,
          fileCount: 0,
        );
      }
      if (progress.status == ArchiveDownloadStatus.extracting) {
        return DatasetExtractionStatus(
          isExtracted: false,
          isDownloading: true,
          progress: progress.progress,
          fileCount: progress.extractedFiles,
        );
      }
      if (progress.status == ArchiveDownloadStatus.completed) {
        return DatasetExtractionStatus(
          isExtracted: true,
          isDownloading: false,
          progress: 1.0,
          fileCount: progress.extractedFiles,
        );
      }
    }

    if (isExtractedResult) {
      final count = await getExtractedFileCount(datasetName);
      return DatasetExtractionStatus(
        isExtracted: true,
        isDownloading: false,
        progress: 1.0,
        fileCount: count,
      );
    }

    return const DatasetExtractionStatus(
      isExtracted: false,
      isDownloading: false,
      progress: 0.0,
      fileCount: 0,
    );
  }
}

/// Status of a dataset's extraction state
class DatasetExtractionStatus {
  final bool isExtracted;
  final bool isDownloading;
  final double progress;
  final int fileCount;

  const DatasetExtractionStatus({
    required this.isExtracted,
    required this.isDownloading,
    required this.progress,
    required this.fileCount,
  });
}
