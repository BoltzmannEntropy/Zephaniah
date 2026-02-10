import 'search_result.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadTask {
  final String id;
  final SearchResult source;
  final String destinationPath;
  final DownloadStatus status;
  final int bytesReceived;
  final int? totalBytes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;

  const DownloadTask({
    required this.id,
    required this.source,
    required this.destinationPath,
    this.status = DownloadStatus.queued,
    this.bytesReceived = 0,
    this.totalBytes,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  double get progress {
    if (totalBytes == null || totalBytes == 0) return 0;
    return bytesReceived / totalBytes!;
  }

  int get progressPercent => (progress * 100).round();

  String get progressFormatted {
    if (totalBytes == null) {
      return _formatBytes(bytesReceived);
    }
    return '${_formatBytes(bytesReceived)} / ${_formatBytes(totalBytes!)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading;

  bool get isComplete => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPaused => status == DownloadStatus.paused;
  bool get canRetry => isFailed && retryCount < 3;

  DownloadTask copyWith({
    String? id,
    SearchResult? source,
    String? destinationPath,
    DownloadStatus? status,
    int? bytesReceived,
    int? totalBytes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      source: source ?? this.source,
      destinationPath: destinationPath ?? this.destinationPath,
      status: status ?? this.status,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
