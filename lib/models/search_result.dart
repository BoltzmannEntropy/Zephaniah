import 'search_query.dart';

class SearchResult {
  final String id;
  final String title;
  final String url;
  final String? snippet;
  final FileType? fileType;
  final String? fileSize;
  final String? sourceDomain;
  final DateTime? publishDate;

  const SearchResult({
    required this.id,
    required this.title,
    required this.url,
    this.snippet,
    this.fileType,
    this.fileSize,
    this.sourceDomain,
    this.publishDate,
  });

  String get domain {
    if (sourceDomain != null) return sourceDomain!;
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'unknown';
    }
  }

  String get filename {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (_) {}
    return title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'snippet': snippet,
        'file_type': fileType?.extension,
        'file_size': fileSize,
        'source_domain': sourceDomain,
        'publish_date': publishDate?.toIso8601String(),
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      snippet: json['snippet'] as String?,
      fileType: json['file_type'] != null
          ? FileType.fromExtension(json['file_type'] as String)
          : null,
      fileSize: json['file_size'] as String?,
      sourceDomain: json['source_domain'] as String?,
      publishDate: json['publish_date'] != null
          ? DateTime.parse(json['publish_date'] as String)
          : null,
    );
  }

  SearchResult copyWith({
    String? id,
    String? title,
    String? url,
    String? snippet,
    FileType? fileType,
    String? fileSize,
    String? sourceDomain,
    DateTime? publishDate,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      snippet: snippet ?? this.snippet,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      sourceDomain: sourceDomain ?? this.sourceDomain,
      publishDate: publishDate ?? this.publishDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

class SearchResultBatch {
  final String searchId;
  final String query;
  final List<SearchResult> results;
  final int totalResults;
  final DateTime searchedAt;
  final String engine;
  final bool hasMore;
  final int page;

  const SearchResultBatch({
    required this.searchId,
    required this.query,
    required this.results,
    required this.totalResults,
    required this.searchedAt,
    required this.engine,
    this.hasMore = false,
    this.page = 1,
  });

  Map<String, dynamic> toJson() => {
        'search_id': searchId,
        'query': query,
        'results': results.map((r) => r.toJson()).toList(),
        'total_results': totalResults,
        'searched_at': searchedAt.toIso8601String(),
        'engine': engine,
        'has_more': hasMore,
        'page': page,
      };

  factory SearchResultBatch.fromJson(Map<String, dynamic> json) {
    return SearchResultBatch(
      searchId: json['search_id'] as String,
      query: json['query'] as String,
      results: (json['results'] as List)
          .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalResults: json['total_results'] as int,
      searchedAt: DateTime.parse(json['searched_at'] as String),
      engine: json['engine'] as String,
      hasMore: json['has_more'] as bool? ?? false,
      page: json['page'] as int? ?? 1,
    );
  }
}
