enum SnapshotStatus {
  running,
  completed,
  failed,
  cancelled,
}

class Snapshot {
  final String id;
  final DateTime snapshotDate;
  final String searchTerms;
  final List<String> institutionsUsed;
  final int artifactsFound;
  final int artifactsDownloaded;
  final int newArtifacts;
  final int duplicatesSkipped;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SnapshotStatus status;
  final String? errorMessage;

  const Snapshot({
    required this.id,
    required this.snapshotDate,
    required this.searchTerms,
    required this.institutionsUsed,
    this.artifactsFound = 0,
    this.artifactsDownloaded = 0,
    this.newArtifacts = 0,
    this.duplicatesSkipped = 0,
    required this.startedAt,
    this.completedAt,
    this.status = SnapshotStatus.running,
    this.errorMessage,
  });

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  String get durationFormatted {
    final d = duration;
    if (d == null) return 'Running...';
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  bool get isComplete => status == SnapshotStatus.completed;
  bool get isRunning => status == SnapshotStatus.running;
  bool get isFailed => status == SnapshotStatus.failed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'snapshot_date': snapshotDate.toIso8601String(),
        'search_terms': searchTerms,
        'institutions_used': institutionsUsed.join(','),
        'artifacts_found': artifactsFound,
        'artifacts_downloaded': artifactsDownloaded,
        'new_artifacts': newArtifacts,
        'duplicates_skipped': duplicatesSkipped,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'status': status.name,
        'error_message': errorMessage,
      };

  factory Snapshot.fromJson(Map<String, dynamic> json) {
    final institutionsStr = json['institutions_used'] as String? ?? '';
    return Snapshot(
      id: json['id'] as String,
      snapshotDate: DateTime.parse(json['snapshot_date'] as String),
      searchTerms: json['search_terms'] as String,
      institutionsUsed: institutionsStr.isEmpty
          ? []
          : institutionsStr.split(','),
      artifactsFound: json['artifacts_found'] as int? ?? 0,
      artifactsDownloaded: json['artifacts_downloaded'] as int? ?? 0,
      newArtifacts: json['new_artifacts'] as int? ?? 0,
      duplicatesSkipped: json['duplicates_skipped'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      status: SnapshotStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SnapshotStatus.running,
      ),
      errorMessage: json['error_message'] as String?,
    );
  }

  Snapshot copyWith({
    String? id,
    DateTime? snapshotDate,
    String? searchTerms,
    List<String>? institutionsUsed,
    int? artifactsFound,
    int? artifactsDownloaded,
    int? newArtifacts,
    int? duplicatesSkipped,
    DateTime? startedAt,
    DateTime? completedAt,
    SnapshotStatus? status,
    String? errorMessage,
  }) {
    return Snapshot(
      id: id ?? this.id,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      searchTerms: searchTerms ?? this.searchTerms,
      institutionsUsed: institutionsUsed ?? this.institutionsUsed,
      artifactsFound: artifactsFound ?? this.artifactsFound,
      artifactsDownloaded: artifactsDownloaded ?? this.artifactsDownloaded,
      newArtifacts: newArtifacts ?? this.newArtifacts,
      duplicatesSkipped: duplicatesSkipped ?? this.duplicatesSkipped,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Snapshot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
