import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'search_provider.dart';

class DuckDuckGoSearchProvider implements SearchProvider {
  @override
  String get name => 'DuckDuckGo';

  @override
  String get code => 'duckduckgo';

  @override
  String get description => 'DuckDuckGo Privacy-Focused Search';

  @override
  bool get enabled => true;

  final _uuid = const Uuid();

  @override
  String buildSearchUrl(SearchQuery query, {int page = 1}) {
    final queryStr = query.buildQuery();

    final params = <String, String>{
      'q': queryStr,
      'kl': 'us-en',
    };

    // DuckDuckGo time filter
    final timeFilter = _getTimeFilter(query.timeRange);
    if (timeFilter != null) {
      params['df'] = timeFilter;
    }

    final uri = Uri.https('html.duckduckgo.com', '/html/', params);
    return uri.toString();
  }

  String? _getTimeFilter(TimeRange timeRange) {
    switch (timeRange) {
      case TimeRange.lastDay:
        return 'd';
      case TimeRange.lastWeek:
        return 'w';
      case TimeRange.lastMonth:
        return 'm';
      case TimeRange.lastYear:
        return 'y';
      default:
        return null;
    }
  }

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Origin': 'https://html.duckduckgo.com',
    'Referer': 'https://html.duckduckgo.com/',
  };

  @override
  Future<SearchResultBatch> search(SearchQuery query, {int page = 1}) async {
    final searchId = _uuid.v4();
    final queryStr = query.buildQuery();
    final maxResults = query.maxResults;
    final seenUrls = <String>{};
    final allResults = <SearchResult>[];

    // Add time filter
    final timeFilter = _getTimeFilter(query.timeRange);

    try {
      String? vqd; // Session token for pagination
      int offset = 0;
      int pageNum = 0;
      const maxPages = 10; // Safety limit

      while (allResults.length < maxResults && pageNum < maxPages) {
        // Build form data for POST request
        final formData = <String, String>{
          'q': queryStr,
          'kl': 'us-en',
        };

        if (timeFilter != null) {
          formData['df'] = timeFilter;
        }

        // Add pagination params for subsequent pages
        if (pageNum > 0 && vqd != null) {
          formData['s'] = offset.toString();
          formData['dc'] = (offset + 1).toString();
          formData['v'] = 'l';
          formData['o'] = 'json';
          formData['api'] = 'd.js';
          formData['vqd'] = vqd;
        }

        // Retry logic for first page (CAPTCHA can be transient)
        http.Response? response;
        String? body;
        final maxRetries = pageNum == 0 ? 3 : 1;

        for (var retry = 0; retry < maxRetries; retry++) {
          if (retry > 0) {
            await Future.delayed(Duration(seconds: retry * 2));
          }

          response = await http.post(
            Uri.parse('https://html.duckduckgo.com/html/'),
            headers: _headers,
            body: formData,
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode != 200) {
            continue;
          }

          body = response.body;

          // Check for bot detection / CAPTCHA page
          if (body.contains('cc=botnet') || body.contains('anomaly-modal')) {
            body = null;
            continue;
          }

          break; // Success
        }

        if (response == null || response.statusCode != 200) {
          if (pageNum == 0) {
            throw SearchProviderException(
              'Failed to fetch search results (status: ${response?.statusCode})',
              provider: name,
              statusCode: response?.statusCode,
            );
          }
          break;
        }

        if (body == null) {
          if (pageNum == 0) {
            throw SearchProviderException(
              'DuckDuckGo is showing a CAPTCHA. Try again in a few minutes.',
              provider: name,
            );
          }
          break;
        }

        // Extract vqd token from first page for pagination
        if (pageNum == 0) {
          final vqdMatch = RegExp(r'name="vqd" value="([^"]+)"').firstMatch(body);
          vqd = vqdMatch?.group(1);
        }

        final pageResults = _parseResults(body, seenUrls);

        if (pageResults.isEmpty) {
          break; // No more results
        }

        allResults.addAll(pageResults);
        offset += pageResults.length;
        pageNum++;

        // Delay between requests to avoid rate limiting (longer for pagination)
        if (allResults.length < maxResults && pageNum < maxPages) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      // Filter by file type client-side (DDG's filetype: is loose)
      var results = allResults;
      if (query.fileTypes.isNotEmpty) {
        results = results.where((r) {
          if (r.fileType == null) return false;
          return query.fileTypes.contains(r.fileType);
        }).toList();
      }

      // Limit to maxResults
      if (results.length > maxResults) {
        results = results.sublist(0, maxResults);
      }

      return SearchResultBatch(
        searchId: searchId,
        query: queryStr,
        results: results,
        totalResults: results.length,
        searchedAt: DateTime.now(),
        engine: code,
        hasMore: allResults.length >= maxResults,
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

  List<SearchResult> _parseResults(String html, Set<String> seenUrls) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    // DuckDuckGo HTML search results - look for result divs
    final resultElements = document.querySelectorAll('div.result');

    for (final element in resultElements) {
      try {
        // Find the main result link (class="result__a")
        final linkElement = element.querySelector('a.result__a');
        if (linkElement == null) continue;

        var href = linkElement.attributes['href'];
        if (href == null) continue;

        // Handle DuckDuckGo redirect URLs (uddg parameter)
        if (href.contains('duckduckgo.com/l/') || href.contains('uddg=')) {
          final uri = Uri.parse(href);
          final uddg = uri.queryParameters['uddg'];
          if (uddg != null) {
            href = Uri.decodeComponent(uddg);
          }
        }

        // Skip non-http links and DuckDuckGo internal links
        if (!href.startsWith('http')) continue;
        if (href.contains('duckduckgo.com')) continue;

        // Skip duplicates
        if (seenUrls.contains(href)) continue;
        seenUrls.add(href);

        // Get title - remove file type prefix if present
        var title = linkElement.text.trim();
        // Remove [PDF] or similar prefixes
        title = title.replaceFirst(RegExp(r'^\[?\w+\]?\s*'), '');
        if (title.isEmpty) {
          // Try to get title from result__title
          final titleEl = element.querySelector('h2.result__title');
          title = titleEl?.text.trim() ?? 'Untitled';
        }

        // Find snippet
        final snippetElement = element.querySelector('a.result__snippet') ??
            element.querySelector('.result__snippet');
        final snippet = snippetElement?.text.trim();

        // Determine file type from URL
        FileType? fileType;
        final lowerUrl = href.toLowerCase();
        for (final type in FileType.values) {
          if (lowerUrl.endsWith('.${type.extension}') ||
              lowerUrl.contains('.${type.extension}?') ||
              lowerUrl.contains('.${type.extension}&') ||
              lowerUrl.contains('.${type.extension}/')) {
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
