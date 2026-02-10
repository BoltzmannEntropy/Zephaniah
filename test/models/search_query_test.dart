import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephaniah/models/models.dart';

void main() {
  group('FileType', () {
    test('fromExtension returns correct type', () {
      expect(FileType.fromExtension('pdf'), FileType.pdf);
      expect(FileType.fromExtension('PDF'), FileType.pdf);
      expect(FileType.fromExtension('.pdf'), FileType.pdf);
      expect(FileType.fromExtension('mp3'), FileType.mp3);
      expect(FileType.fromExtension('unknown'), isNull);
    });

    test('generates correct filetype filter', () {
      expect(FileType.pdf.fileTypeFilter, 'filetype:pdf');
      expect(FileType.doc.fileTypeFilter, 'filetype:doc');
      expect(FileType.mp4.fileTypeFilter, 'filetype:mp4');
    });
  });

  group('TimeRange', () {
    test('has correct google params', () {
      expect(TimeRange.lastDay.googleParam, 'qdr:d');
      expect(TimeRange.lastWeek.googleParam, 'qdr:w');
      expect(TimeRange.lastMonth.googleParam, 'qdr:m');
      expect(TimeRange.lastYear.googleParam, 'qdr:y');
      expect(TimeRange.anytime.googleParam, isNull);
    });
  });

  group('SearchQuery', () {
    test('builds simple query', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
      );

      expect(query.buildQuery(), 'test');
    });

    test('quotes multi-word terms', () {
      final query = SearchQuery(
        terms: 'test query',
        institutions: [],
        fileTypes: [],
      );

      expect(query.buildQuery(), '"test query"');
    });

    test('adds site filters', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [
          const Institution(
            id: 'fbi',
            name: 'FBI',
            urlPattern: 'fbi.gov',
            category: 'Law',
            color: Colors.red,
          ),
        ],
        fileTypes: [],
      );

      expect(query.buildQuery(), 'test site:fbi.gov');
    });

    test('combines multiple site filters with OR', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [
          const Institution(
            id: 'fbi',
            name: 'FBI',
            urlPattern: 'fbi.gov',
            category: 'Law',
            color: Colors.red,
          ),
          const Institution(
            id: 'doj',
            name: 'DOJ',
            urlPattern: 'justice.gov',
            category: 'Law',
            color: Colors.purple,
          ),
        ],
        fileTypes: [],
      );

      expect(query.buildQuery(), 'test (site:fbi.gov OR site:justice.gov)');
    });

    test('adds file type filters', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [FileType.pdf],
      );

      expect(query.buildQuery(), 'test filetype:pdf');
    });

    test('combines multiple file type filters with OR', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [FileType.pdf, FileType.doc],
      );

      expect(query.buildQuery(), 'test (filetype:pdf OR filetype:doc)');
    });

    test('builds complex query with all filters', () {
      final query = SearchQuery(
        terms: 'Jeffrey Epstein',
        institutions: [
          const Institution(
            id: 'fbi',
            name: 'FBI',
            urlPattern: 'fbi.gov',
            category: 'Law',
            color: Colors.red,
          ),
        ],
        fileTypes: [FileType.pdf],
      );

      expect(
        query.buildQuery(),
        '"Jeffrey Epstein" site:fbi.gov filetype:pdf',
      );
    });

    test('converts to and from JSON', () {
      final institutions = [
        const Institution(
          id: 'fbi',
          name: 'FBI',
          urlPattern: 'fbi.gov',
          category: 'Law',
          color: Colors.red,
        ),
      ];

      final original = SearchQuery(
        terms: 'test query',
        institutions: institutions,
        fileTypes: [FileType.pdf, FileType.doc],
        timeRange: TimeRange.lastWeek,
        engine: SearchEngine.google,
        maxResults: 100,
      );

      final json = original.toJson();
      final restored = SearchQuery.fromJson(json, institutions);

      expect(restored.terms, original.terms);
      expect(restored.fileTypes, original.fileTypes);
      expect(restored.timeRange, original.timeRange);
      expect(restored.engine, original.engine);
      expect(restored.maxResults, original.maxResults);
    });

    test('copyWith creates modified copy', () {
      final original = SearchQuery(
        terms: 'original',
        institutions: [],
        fileTypes: [FileType.pdf],
      );

      final modified = original.copyWith(
        terms: 'modified',
        fileTypes: [FileType.doc],
      );

      expect(modified.terms, 'modified');
      expect(modified.fileTypes, [FileType.doc]);
      expect(modified.timeRange, original.timeRange);
    });
  });
}
