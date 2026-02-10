import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'log_service.dart';
import 'database_service.dart';
import 'settings_service.dart';

class DuplicateDownloadException implements Exception {
  final String message;
  DuplicateDownloadException(this.message);
  @override
  String toString() => message;
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final SettingsService _settings = SettingsService();
  final _uuid = const Uuid();

  final List<DownloadTask> _queue = [];
  final List<DownloadTask> _completed = [];
  final Map<String, StreamSubscription> _activeDownloads = {};

  List<DownloadTask> get queue => List.unmodifiable(_queue);
  List<DownloadTask> get completed => List.unmodifiable(_completed);
  List<DownloadTask> get active =>
      _queue.where((t) => t.status == DownloadStatus.downloading).toList();

  int get activeCount => active.length;
  int get queuedCount =>
      _queue.where((t) => t.status == DownloadStatus.queued).length;
  int get completedCount => _completed.length;
  int get failedCount =>
      _queue.where((t) => t.status == DownloadStatus.failed).length;

  bool get hasActiveDownloads => activeCount > 0;

  Future<DownloadTask> enqueue(SearchResult result, {String? searchId}) async {
    // Check for duplicates (but don't fail on database errors)
    try {
      final existing = await _db.getArtifactByUrl(result.url);
      if (existing != null) {
        _log.info('DownloadService', 'Skipping duplicate: ${result.url}');
        throw DuplicateDownloadException('File already downloaded');
      }
    } catch (e) {
      if (e is DuplicateDownloadException) rethrow;
      // Database error - log but continue with download
      _log.warning('DownloadService', 'Database check failed: $e');
    }

    final today = DateTime.now();
    final dateFolder = _settings.getArtifactPath(today);
    await Directory(dateFolder).create(recursive: true);

    final filename = _sanitizeFilename(result.filename, result.fileType);
    final destinationPath = '$dateFolder/$filename';

    final task = DownloadTask(
      id: _uuid.v4(),
      source: result,
      destinationPath: destinationPath,
      createdAt: DateTime.now(),
    );

    _queue.add(task);
    notifyListeners();

    _log.info('DownloadService', 'Enqueued: ${result.title}');

    // Start download if under limit
    _processQueue();

    return task;
  }

  Future<List<DownloadTask>> enqueueAll(
    List<SearchResult> results, {
    String? searchId,
  }) async {
    final tasks = <DownloadTask>[];
    var duplicateCount = 0;
    var errorCount = 0;

    for (final result in results) {
      try {
        final task = await enqueue(result, searchId: searchId);
        tasks.add(task);
      } on DuplicateDownloadException {
        duplicateCount++;
        _log.debug('DownloadService', 'Skipping duplicate: ${result.url}');
      } catch (e) {
        errorCount++;
        _log.error('DownloadService', 'Failed to enqueue ${result.title}: $e');
      }
    }

    if (duplicateCount > 0) {
      _log.info('DownloadService', 'Skipped $duplicateCount duplicates');
    }
    if (errorCount > 0) {
      _log.warning('DownloadService', '$errorCount items failed to enqueue');
    }

    return tasks;
  }

  String _sanitizeFilename(String filename, FileType? fileType) {
    // Remove invalid characters
    var sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Ensure it has the correct extension
    final hasExtension = sanitized.contains('.');
    final expectedExt = fileType?.extension ?? 'pdf';

    if (!hasExtension) {
      sanitized = '$sanitized.$expectedExt';
    } else {
      // Verify the extension matches the file type
      final currentExt = sanitized.split('.').last.toLowerCase();
      if (fileType != null && currentExt != fileType.extension) {
        // Add the correct extension if it doesn't match
        sanitized = '$sanitized.${fileType.extension}';
      }
    }

    // Limit length
    if (sanitized.length > 200) {
      final ext = sanitized.split('.').last;
      sanitized = '${sanitized.substring(0, 190)}.$ext';
    }

    // Handle duplicates by adding timestamp
    final file = File('${_settings.getArtifactPath(DateTime.now())}/$sanitized');
    if (file.existsSync()) {
      final timestamp = DateFormat('HHmmss').format(DateTime.now());
      final parts = sanitized.split('.');
      if (parts.length > 1) {
        final ext = parts.removeLast();
        sanitized = '${parts.join('.')}_$timestamp.$ext';
      } else {
        sanitized = '${sanitized}_$timestamp';
      }
    }

    return sanitized;
  }

  void _processQueue() {
    final maxConcurrent = _settings.settings.concurrentDownloads;
    final available = maxConcurrent - activeCount;

    if (available <= 0) return;

    final pending = _queue
        .where((t) => t.status == DownloadStatus.queued)
        .take(available)
        .toList();

    for (final task in pending) {
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    final index = _queue.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    _queue[index] = task.copyWith(
      status: DownloadStatus.downloading,
      startedAt: DateTime.now(),
    );
    notifyListeners();

    _log.info('DownloadService', 'Starting download: ${task.source.title}');

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(task.source.url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final file = File(task.destinationPath);
      final sink = file.openWrite();

      final subscription = response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;

          final idx = _queue.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            _queue[idx] = _queue[idx].copyWith(
              bytesReceived: receivedBytes,
              totalBytes: totalBytes,
            );
            notifyListeners();
          }
        },
        onDone: () async {
          await sink.close();
          client.close();
          _activeDownloads.remove(task.id);
          await _completeDownload(task, receivedBytes);
        },
        onError: (error) async {
          await sink.close();
          client.close();
          _activeDownloads.remove(task.id);
          await _failDownload(task, error.toString());
        },
        cancelOnError: true,
      );

      _activeDownloads[task.id] = subscription;
    } catch (e) {
      await _failDownload(task, e.toString());
    }
  }

  Future<void> _completeDownload(DownloadTask task, int fileSize) async {
    final index = _queue.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final completedTask = task.copyWith(
      status: DownloadStatus.completed,
      bytesReceived: fileSize,
      totalBytes: fileSize,
      completedAt: DateTime.now(),
    );

    _queue.removeAt(index);
    _completed.add(completedTask);

    // Save to database
    final artifact = Artifact(
      id: task.id,
      searchId: null,
      filename: task.source.filename,
      originalUrl: task.source.url,
      sourceInstitution: task.source.sourceDomain,
      fileType: task.source.fileType,
      fileSize: fileSize,
      filePath: task.destinationPath,
      downloadedAt: DateTime.now(),
      status: ArtifactStatus.completed,
    );
    await _db.insertArtifact(artifact);

    _log.info('DownloadService', 'Completed: ${task.source.title}');
    notifyListeners();

    _processQueue();
  }

  Future<void> _failDownload(DownloadTask task, String error) async {
    final index = _queue.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final maxRetries = _settings.settings.autoRetryAttempts;

    if (task.retryCount < maxRetries) {
      // Retry
      _queue[index] = task.copyWith(
        status: DownloadStatus.queued,
        retryCount: task.retryCount + 1,
        errorMessage: error,
      );
      _log.warning('DownloadService',
          'Retry ${task.retryCount + 1}/$maxRetries: ${task.source.title}');
    } else {
      // Mark as failed
      _queue[index] = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: error,
        completedAt: DateTime.now(),
      );
      _log.error('DownloadService', 'Failed: ${task.source.title} - $error');
    }

    notifyListeners();
    _processQueue();
  }

  void pause(String taskId) {
    final subscription = _activeDownloads[taskId];
    if (subscription != null) {
      subscription.pause();
      final index = _queue.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _queue[index] = _queue[index].copyWith(status: DownloadStatus.paused);
        notifyListeners();
      }
    }
  }

  void resume(String taskId) {
    final subscription = _activeDownloads[taskId];
    if (subscription != null) {
      subscription.resume();
      final index = _queue.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _queue[index] =
            _queue[index].copyWith(status: DownloadStatus.downloading);
        notifyListeners();
      }
    } else {
      // Restart download
      final index = _queue.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _queue[index] = _queue[index].copyWith(status: DownloadStatus.queued);
        notifyListeners();
        _processQueue();
      }
    }
  }

  void cancel(String taskId) {
    final subscription = _activeDownloads.remove(taskId);
    subscription?.cancel();

    _queue.removeWhere((t) => t.id == taskId);
    notifyListeners();

    _processQueue();
  }

  void retry(String taskId) {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index != -1 && _queue[index].status == DownloadStatus.failed) {
      _queue[index] = _queue[index].copyWith(
        status: DownloadStatus.queued,
        retryCount: 0,
        errorMessage: null,
      );
      notifyListeners();
      _processQueue();
    }
  }

  void clearCompleted() {
    _completed.clear();
    notifyListeners();
  }

  void clearFailed() {
    _queue.removeWhere((t) => t.status == DownloadStatus.failed);
    notifyListeners();
  }
}
