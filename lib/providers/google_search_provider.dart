import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'search_provider.dart';

class GoogleSearchProvider implements SearchProvider {
  @override
  String get name => 'Google';

  @override
  String get code => 'google';

  @override
  String get description => 'Google Search Engine';

  @override
  bool get enabled => true;

  final _uuid = const Uuid();

  @override
  String buildSearchUrl(SearchQuery query, {int page = 1}) {
    final queryStr = query.buildQuery();
    final start = (page - 1) * 10;

    final params = <String, String>{
      'q': queryStr,
      'num': '10',
      'start': start.toString(),
      'newwindow': '1',
    };

    // Add time range filter
    if (query.timeRange.googleParam != null) {
      params['tbs'] = query.timeRange.googleParam!;
    } else if (query.timeRange == TimeRange.custom &&
        query.customStartDate != null &&
        query.customEndDate != null) {
      final start = _formatDate(query.customStartDate!);
      final end = _formatDate(query.customEndDate!);
      params['tbs'] = 'cdr:1,cd_min:$start,cd_max:$end';
    }

    final uri = Uri.https('www.google.com', '/search', params);
    return uri.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw SearchProviderException(
          'Failed to fetch search results (status: ${response.statusCode})',
          provider: name,
          statusCode: response.statusCode,
        );
      }

      // Check for consent/captcha/JS challenge pages
      final body = response.body;
      if (body.contains('consent.google.com') ||
          body.contains('sorry/index') ||
          body.contains('unusual traffic') ||
          body.contains('captcha') ||
          body.contains('detected unusual traffic') ||
          body.contains('before_you_go_banner')) {
        throw SearchProviderException(
          'Google is blocking automated requests. Please use DuckDuckGo instead.',
          provider: name,
        );
      }

      // Check for JavaScript challenge page (anti-bot protection)
      if ((body.contains('window.google') && body.contains('nonce=')) ||
          (body.contains('<noscript>') && body.contains('enablejs')) ||
          (body.length > 50000 && !body.contains('class="g"') && !body.contains('data-ved'))) {
        throw SearchProviderException(
          'Google is serving a JavaScript challenge. Please use DuckDuckGo instead.',
          provider: name,
        );
      }

      final results = _parseResults(body);

      // If no results but got a small response, might be blocked
      if (results.isEmpty) {
        // Check if page has "no results" indicator
        if (body.contains('did not match any documents') ||
            body.contains('No results found')) {
          // Legitimate empty results
          return SearchResultBatch(
            searchId: searchId,
            query: query.buildQuery(),
            results: [],
            totalResults: 0,
            searchedAt: DateTime.now(),
            engine: code,
            hasMore: false,
            page: page,
          );
        }
        // Small response with no results is suspicious
        if (body.length < 5000) {
          throw SearchProviderException(
            'Google returned no results. This may be due to rate limiting. Try DuckDuckGo instead.',
            provider: name,
          );
        }
        // Large response but no parsed results - parsing issue
        // Return empty rather than error
      }

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
    final seenUrls = <String>{};

    // Helper to add result if valid and not duplicate
    void addResult(String? href, String? title, String? snippet) {
      if (href == null || !href.startsWith('http')) return;
      if (href.contains('google.com') || href.contains('youtube.com')) return;
      if (seenUrls.contains(href)) return;

      final cleanTitle = title?.trim() ?? 'Untitled';
      if (cleanTitle.isEmpty || cleanTitle == 'Untitled' && (snippet?.isEmpty ?? true)) return;

      seenUrls.add(href);

      // Determine file type from URL
      FileType? fileType;
      final lowerUrl = href.toLowerCase();
      for (final type in FileType.values) {
        if (lowerUrl.endsWith('.${type.extension}') ||
            lowerUrl.contains('.${type.extension}?') ||
            lowerUrl.contains('.${type.extension}&')) {
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
        id: const Uuid().v4(),
        title: cleanTitle,
        url: href,
        snippet: snippet?.trim(),
        fileType: fileType,
        sourceDomain: domain,
      ));
    }

    // Method 1: Standard div.g results
    final resultElements = document.querySelectorAll('div.g');
    for (final element in resultElements) {
      try {
        final linkElement = element.querySelector('a[href]');
        if (linkElement == null) continue;

        final href = linkElement.attributes['href'];
        final titleElement = element.querySelector('h3') ?? linkElement.querySelector('h3');
        final title = titleElement?.text;

        final snippetElement = element.querySelector('div[data-sncf]') ??
            element.querySelector('div.VwiC3b') ??
            element.querySelector('span.aCOpRe') ??
            element.querySelector('div[data-content-feature]');
        final snippet = snippetElement?.text;

        addResult(href, title, snippet);
      } catch (e) {
        continue;
      }
    }

    // Method 2: Results with cite element (file results often have this)
    final citeElements = document.querySelectorAll('cite');
    for (final cite in citeElements) {
      try {
        final parent = cite.parent?.parent?.parent;
        if (parent == null) continue;

        final linkElement = parent.querySelector('a[href]');
        if (linkElement == null) continue;

        final href = linkElement.attributes['href'];
        final titleElement = parent.querySelector('h3');
        final title = titleElement?.text ?? linkElement.text;

        addResult(href, title, cite.text);
      } catch (e) {
        continue;
      }
    }

    // Method 3: Links with data-ved attribute
    final vedLinks = document.querySelectorAll('a[data-ved][href^="http"]');
    for (final link in vedLinks) {
      try {
        final href = link.attributes['href'];
        if (href == null) continue;

        // Look for h3 within the link or nearby
        final h3 = link.querySelector('h3') ?? link.parent?.querySelector('h3');
        final title = h3?.text ?? link.text;

        addResult(href, title, null);
      } catch (e) {
        continue;
      }
    }

    // Method 4: Direct file links (often for PDF/DOC results)
    final allLinks = document.querySelectorAll('a[href]');
    for (final link in allLinks) {
      try {
        final href = link.attributes['href'];
        if (href == null || !href.startsWith('http')) continue;

        final lowerHref = href.toLowerCase();
        // Only look for file extensions we care about
        final hasFileExt = FileType.values.any((t) =>
          lowerHref.endsWith('.${t.extension}') ||
          lowerHref.contains('.${t.extension}?') ||
          lowerHref.contains('.${t.extension}&'));

        if (!hasFileExt) continue;

        final title = link.text.trim();
        if (title.isNotEmpty && title.length > 3) {
          addResult(href, title, null);
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }
}
