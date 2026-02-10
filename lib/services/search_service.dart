import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'log_service.dart';
import 'database_service.dart';
import 'settings_service.dart';

class SearchService extends ChangeNotifier {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final SettingsService _settings = SettingsService();
  final _uuid = const Uuid();

  final Map<String, SearchProvider> _providers = {};
  bool _isSearching = false;
  SearchResultBatch? _lastResults;
  String? _lastError;

  bool get isSearching => _isSearching;
  SearchResultBatch? get lastResults => _lastResults;
  String? get lastError => _lastError;
  List<SearchProvider> get providers => _providers.values.toList();

  void initialize() {
    // Register built-in providers
    _registerProvider(GoogleSearchProvider());
    _registerProvider(BingSearchProvider());
    _registerProvider(DuckDuckGoSearchProvider());
    _log.info('SearchService', 'Initialized with ${_providers.length} providers');
  }

  void _registerProvider(SearchProvider provider) {
    _providers[provider.code] = provider;
  }

  SearchProvider? getProvider(String code) => _providers[code];

  SearchProvider? getProviderForEngine(SearchEngine engine) =>
      _providers[engine.code];

  Future<SearchResultBatch> search(SearchQuery query, {int page = 1}) async {
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      final provider = getProviderForEngine(query.engine);
      if (provider == null) {
        throw SearchProviderException(
          'No provider found for ${query.engine.label}',
        );
      }

      _log.info('SearchService',
          'Searching with ${provider.name}: ${query.buildQuery()}');

      final results = await provider.search(query, page: page);
      _lastResults = results;

      // Save to history
      if (page == 1) {
        final history = SearchHistory.fromQuery(
          results.searchId,
          query,
          results.totalResults,
        );
        await _db.insertSearch(history);
      }

      _log.info('SearchService',
          'Found ${results.results.length} results');

      return results;
    } catch (e) {
      _lastError = e.toString();
      _log.error('SearchService', 'Search failed: $e');
      rethrow;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<List<SearchResultBatch>> searchAllProviders(SearchQuery query) async {
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    final results = <SearchResultBatch>[];

    try {
      for (final provider in _providers.values) {
        if (!provider.enabled) continue;

        try {
          final batch = await provider.search(query);
          results.add(batch);
          _log.info('SearchService',
              '${provider.name}: ${batch.results.length} results');
        } catch (e) {
          _log.warning('SearchService',
              '${provider.name} failed: $e');
        }
      }

      // Merge and deduplicate results
      if (results.isNotEmpty) {
        _lastResults = _mergeResults(results);
      }

      return results;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  SearchResultBatch _mergeResults(List<SearchResultBatch> batches) {
    final allResults = <SearchResult>[];
    final seenUrls = <String>{};

    for (final batch in batches) {
      for (final result in batch.results) {
        if (!seenUrls.contains(result.url)) {
          seenUrls.add(result.url);
          allResults.add(result);
        }
      }
    }

    return SearchResultBatch(
      searchId: _uuid.v4(),
      query: batches.first.query,
      results: allResults,
      totalResults: allResults.length,
      searchedAt: DateTime.now(),
      engine: 'merged',
      hasMore: false,
      page: 1,
    );
  }

  SearchQuery buildDefaultQuery() {
    final settings = _settings.settings;

    final fileTypes = settings.defaultFileTypes
        .map((ext) => FileType.fromExtension(ext))
        .whereType<FileType>()
        .toList();

    final timeRange = TimeRange.values.firstWhere(
      (t) => t.name == settings.defaultTimeRange,
      orElse: () => TimeRange.lastWeek,
    );

    final engine = SearchEngine.values.firstWhere(
      (e) => e.code == settings.defaultSearchEngine,
      orElse: () => SearchEngine.duckduckgo,
    );

    // Get institutions
    final allInstitutions = [
      ...DefaultInstitutions.all,
    ];

    final selectedInstitutions = allInstitutions
        .where((i) => settings.defaultInstitutions.contains(i.id))
        .toList();

    return SearchQuery(
      terms: settings.defaultSearchTerms,
      fileTypes: fileTypes.isEmpty ? [FileType.pdf] : fileTypes,
      timeRange: timeRange,
      engine: engine,
      institutions: selectedInstitutions,
    );
  }

  void clearResults() {
    _lastResults = null;
    _lastError = null;
    notifyListeners();
  }
}
