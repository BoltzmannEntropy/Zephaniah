import 'search_query.dart';

enum ArtifactStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
}

class Artifact {
  final String id;
  final String? searchId;
  final String filename;
  final String originalUrl;
  final String? sourceInstitution;
  final FileType? fileType;
  final int? fileSize;
  final String filePath;
  final DateTime downloadedAt;
  final ArtifactStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const Artifact({
    required this.id,
    this.searchId,
    required this.filename,
    required this.originalUrl,
    this.sourceInstitution,
    this.fileType,
    this.fileSize,
    required this.filePath,
    required this.downloadedAt,
    this.status = ArtifactStatus.completed,
    this.errorMessage,
    this.metadata,
  });

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get domain {
    try {
      return Uri.parse(originalUrl).host;
    } catch (_) {
      return 'unknown';
    }
  }

  bool get isPdf => fileType == FileType.pdf;
  bool get isAudio =>
      fileType == FileType.mp3 || fileType == FileType.wav;
  bool get isVideo =>
      fileType == FileType.mp4 || fileType == FileType.mov;
  bool get isDocument =>
      fileType == FileType.doc ||
      fileType == FileType.docx ||
      fileType == FileType.txt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'search_id': searchId,
        'filename': filename,
        'original_url': originalUrl,
        'source_institution': sourceInstitution,
        'file_type': fileType?.extension,
        'file_size': fileSize,
        'file_path': filePath,
        'downloaded_at': downloadedAt.toIso8601String(),
        'status': status.name,
        'error_message': errorMessage,
        'metadata_json': metadata,
      };

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String,
      searchId: json['search_id'] as String?,
      filename: json['filename'] as String,
      originalUrl: json['original_url'] as String,
      sourceInstitution: json['source_institution'] as String?,
      fileType: json['file_type'] != null
          ? FileType.fromExtension(json['file_type'] as String)
          : null,
      fileSize: json['file_size'] as int?,
      filePath: json['file_path'] as String,
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      status: ArtifactStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ArtifactStatus.completed,
      ),
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata_json'] as Map<String, dynamic>?,
    );
  }

  Artifact copyWith({
    String? id,
    String? searchId,
    String? filename,
    String? originalUrl,
    String? sourceInstitution,
    FileType? fileType,
    int? fileSize,
    String? filePath,
    DateTime? downloadedAt,
    ArtifactStatus? status,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Artifact(
      id: id ?? this.id,
      searchId: searchId ?? this.searchId,
      filename: filename ?? this.filename,
      originalUrl: originalUrl ?? this.originalUrl,
      sourceInstitution: sourceInstitution ?? this.sourceInstitution,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artifact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
