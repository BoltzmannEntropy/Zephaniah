import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephaniah/models/models.dart';
import 'package:zephaniah/providers/providers.dart';

void main() {
  group('GoogleSearchProvider', () {
    late GoogleSearchProvider provider;

    setUp(() {
      provider = GoogleSearchProvider();
    });

    test('has correct properties', () {
      expect(provider.name, 'Google');
      expect(provider.code, 'google');
      expect(provider.enabled, true);
    });

    test('builds correct search URL for simple query', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        timeRange: TimeRange.anytime,
        engine: SearchEngine.google,
      );

      final url = provider.buildSearchUrl(query);
      expect(url, contains('google.com/search'));
      expect(url, contains('q=test'));
    });

    test('builds URL with time range filter', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        timeRange: TimeRange.lastWeek,
        engine: SearchEngine.google,
      );

      final url = provider.buildSearchUrl(query);
      expect(url, contains('tbs=qdr%3Aw'));
    });

    test('handles pagination', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        engine: SearchEngine.google,
      );

      final page1Url = provider.buildSearchUrl(query, page: 1);
      final page2Url = provider.buildSearchUrl(query, page: 2);

      expect(page1Url, contains('start=0'));
      expect(page2Url, contains('start=10'));
    });
  });

  group('BingSearchProvider', () {
    late BingSearchProvider provider;

    setUp(() {
      provider = BingSearchProvider();
    });

    test('has correct properties', () {
      expect(provider.name, 'Bing');
      expect(provider.code, 'bing');
      expect(provider.enabled, true);
    });

    test('builds correct search URL', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        engine: SearchEngine.bing,
      );

      final url = provider.buildSearchUrl(query);
      expect(url, contains('bing.com/search'));
      expect(url, contains('q=test'));
    });

    test('handles pagination with first parameter', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        engine: SearchEngine.bing,
      );

      final page1Url = provider.buildSearchUrl(query, page: 1);
      final page2Url = provider.buildSearchUrl(query, page: 2);

      expect(page1Url, contains('first=1'));
      expect(page2Url, contains('first=11'));
    });
  });

  group('DuckDuckGoSearchProvider', () {
    late DuckDuckGoSearchProvider provider;

    setUp(() {
      provider = DuckDuckGoSearchProvider();
    });

    test('has correct properties', () {
      expect(provider.name, 'DuckDuckGo');
      expect(provider.code, 'duckduckgo');
      expect(provider.enabled, true);
    });

    test('builds correct search URL', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        engine: SearchEngine.duckduckgo,
      );

      final url = provider.buildSearchUrl(query);
      expect(url, contains('duckduckgo.com'));
      expect(url, contains('q=test'));
    });

    test('adds time filter parameter', () {
      final query = SearchQuery(
        terms: 'test',
        institutions: [],
        fileTypes: [],
        timeRange: TimeRange.lastWeek,
        engine: SearchEngine.duckduckgo,
      );

      final url = provider.buildSearchUrl(query);
      expect(url, contains('df=w'));
    });
  });

  group('Search Query Building', () {
    test('complex query is encoded correctly in URL', () {
      final provider = GoogleSearchProvider();
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
        timeRange: TimeRange.lastMonth,
        engine: SearchEngine.google,
      );

      final url = provider.buildSearchUrl(query);

      // URL should contain encoded query parts
      expect(url, contains('google.com/search'));
      expect(url, contains('q='));
      expect(url, contains('tbs=qdr%3Am')); // lastMonth
    });
  });
}
