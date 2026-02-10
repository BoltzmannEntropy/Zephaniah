import 'package:flutter_test/flutter_test.dart';
import 'package:zephaniah/models/models.dart';

void main() {
  group('Artifact', () {
    test('creates artifact with all properties', () {
      final artifact = Artifact(
        id: 'test_id',
        searchId: 'search_123',
        filename: 'document.pdf',
        originalUrl: 'https://fbi.gov/document.pdf',
        sourceInstitution: 'FBI',
        fileType: FileType.pdf,
        fileSize: 1024 * 1024, // 1 MB
        filePath: '/path/to/document.pdf',
        downloadedAt: DateTime(2024, 1, 1),
        status: ArtifactStatus.completed,
      );

      expect(artifact.id, 'test_id');
      expect(artifact.filename, 'document.pdf');
      expect(artifact.isPdf, true);
      expect(artifact.isAudio, false);
      expect(artifact.isVideo, false);
    });

    test('formats file size correctly', () {
      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileSize: 500,
        ).fileSizeFormatted,
        '500 B',
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileSize: 1024,
        ).fileSizeFormatted,
        '1.0 KB',
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileSize: 1024 * 1024,
        ).fileSizeFormatted,
        '1.0 MB',
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileSize: 1024 * 1024 * 1024,
        ).fileSizeFormatted,
        '1.0 GB',
      );
    });

    test('extracts domain from URL', () {
      final artifact = Artifact(
        id: '1',
        filename: 'test',
        originalUrl: 'https://fbi.gov/documents/test.pdf',
        filePath: 'path',
        downloadedAt: DateTime.now(),
      );

      expect(artifact.domain, 'fbi.gov');
    });

    test('detects file types correctly', () {
      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileType: FileType.pdf,
        ).isPdf,
        true,
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileType: FileType.mp3,
        ).isAudio,
        true,
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileType: FileType.mp4,
        ).isVideo,
        true,
      );

      expect(
        Artifact(
          id: '1',
          filename: 'test',
          originalUrl: 'url',
          filePath: 'path',
          downloadedAt: DateTime.now(),
          fileType: FileType.doc,
        ).isDocument,
        true,
      );
    });

    test('converts to and from JSON', () {
      final original = Artifact(
        id: 'test_id',
        searchId: 'search_123',
        filename: 'document.pdf',
        originalUrl: 'https://fbi.gov/document.pdf',
        sourceInstitution: 'FBI',
        fileType: FileType.pdf,
        fileSize: 1024,
        filePath: '/path/to/document.pdf',
        downloadedAt: DateTime(2024, 1, 1, 12, 0, 0),
        status: ArtifactStatus.completed,
      );

      final json = original.toJson();
      final restored = Artifact.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.searchId, original.searchId);
      expect(restored.filename, original.filename);
      expect(restored.originalUrl, original.originalUrl);
      expect(restored.fileType, original.fileType);
      expect(restored.fileSize, original.fileSize);
      expect(restored.status, original.status);
    });

    test('copyWith creates modified copy', () {
      final original = Artifact(
        id: 'test_id',
        filename: 'document.pdf',
        originalUrl: 'url',
        filePath: 'path',
        downloadedAt: DateTime.now(),
        status: ArtifactStatus.queued,
      );

      final modified = original.copyWith(
        status: ArtifactStatus.completed,
        fileSize: 2048,
      );

      expect(modified.id, original.id);
      expect(modified.status, ArtifactStatus.completed);
      expect(modified.fileSize, 2048);
    });

    test('equality based on id', () {
      final artifact1 = Artifact(
        id: 'same_id',
        filename: 'file1.pdf',
        originalUrl: 'url1',
        filePath: 'path1',
        downloadedAt: DateTime.now(),
      );

      final artifact2 = Artifact(
        id: 'same_id',
        filename: 'file2.pdf',
        originalUrl: 'url2',
        filePath: 'path2',
        downloadedAt: DateTime.now(),
      );

      expect(artifact1, artifact2);
    });
  });
}
