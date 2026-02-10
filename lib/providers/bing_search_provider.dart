import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'search_provider.dart';

class BingSearchProvider implements SearchProvider {
  @override
  String get name => 'Bing';

  @override
  String get code => 'bing';

  @override
  String get description => 'Microsoft Bing Search Engine';

  @override
  bool get enabled => true;

  final _uuid = const Uuid();

  @override
  String buildSearchUrl(SearchQuery query, {int page = 1}) {
    final queryStr = query.buildQuery();
    final first = ((page - 1) * 10) + 1;

    final params = <String, String>{
      'q': queryStr,
      'first': first.toString(),
      'count': '10',
    };

    // Add time range filter
    final timeFilter = _getTimeFilter(query.timeRange);
    if (timeFilter != null) {
      params['filters'] = timeFilter;
    }

    final uri = Uri.https('www.bing.com', '/search', params);
    return uri.toString();
  }

  String? _getTimeFilter(TimeRange timeRange) {
    switch (timeRange) {
      case TimeRange.lastDay:
        return 'ex1:"ez1"';
      case TimeRange.lastWeek:
        return 'ex1:"ez2"';
      case TimeRange.lastMonth:
        return 'ex1:"ez3"';
      case TimeRange.lastYear:
        return 'ex1:"ez5_21231_21596"';
      default:
        return null;
    }
  }

  @override
  Future<SearchResultBatch> search(SearchQuery query, {int page = 1}) async {
    final url = buildSearchUrl(query, page: page);
    final searchId = _uuid.v4();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw SearchProviderException(
          'Failed to fetch search results',
          provider: name,
          statusCode: response.statusCode,
        );
      }

      final results = _parseResults(response.body);

      return SearchResultBatch(
        searchId: searchId,
        query: query.buildQuery(),
        results: results,
        totalResults: results.length,
        searchedAt: DateTime.now(),
        engine: code,
        hasMore: results.length >= 10,
        page: page,
      );
    } catch (e) {
      if (e is SearchProviderException) rethrow;
      throw SearchProviderException(
        'Search failed: $e',
        provider: name,
      );
    }
  }

  List<SearchResult> _parseResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    // Bing search results
    final resultElements = document.querySelectorAll('li.b_algo');

    for (final element in resultElements) {
      try {
        // Find the link
        final linkElement = element.querySelector('h2 a');
        if (linkElement == null) continue;

        final href = linkElement.attributes['href'];
        if (href == null || !href.startsWith('http')) continue;

        final title = linkElement.text.trim();
        if (title.isEmpty) continue;

        // Find snippet
        final snippetElement = element.querySelector('div.b_caption p');
        final snippet = snippetElement?.text.trim();

        // Determine file type from URL
        FileType? fileType;
        final lowerUrl = href.toLowerCase();
        for (final type in FileType.values) {
          if (lowerUrl.contains('.${type.extension}')) {
            fileType = type;
            break;
          }
        }

        // Extract domain
        String? domain;
        try {
          domain = Uri.parse(href).host;
        } catch (_) {}

        results.add(SearchResult(
          id: _uuid.v4(),
          title: title,
          url: href,
          snippet: snippet,
          fileType: fileType,
          sourceDomain: domain,
        ));
      } catch (e) {
        continue;
      }
    }

    return results;
  }
}
