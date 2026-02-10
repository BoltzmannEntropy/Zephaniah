import '../models/models.dart';

abstract class SearchProvider {
  String get name;
  String get code;
  String get description;
  bool get enabled;

  Future<SearchResultBatch> search(SearchQuery query, {int page = 1});

  String buildSearchUrl(SearchQuery query, {int page = 1});
}

class SearchProviderException implements Exception {
  final String message;
  final String? provider;
  final int? statusCode;

  const SearchProviderException(
    this.message, {
    this.provider,
    this.statusCode,
  });

  @override
  String toString() =>
      'SearchProviderException: $message${provider != null ? ' (provider: $provider)' : ''}${statusCode != null ? ' [status: $statusCode]' : ''}';
}
