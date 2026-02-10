import 'search_query.dart';

class SearchHistory {
  final String id;
  final String queryTerms;
  final List<String> fileTypes;
  final String timeRange;
  final List<String> institutions;
  final String searchEngine;
  final DateTime createdAt;
  final int resultCount;

  const SearchHistory({
    required this.id,
    required this.queryTerms,
    required this.fileTypes,
    required this.timeRange,
    required this.institutions,
    required this.searchEngine,
    required this.createdAt,
    this.resultCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'query_terms': queryTerms,
        'file_types': fileTypes.join(','),
        'time_range': timeRange,
        'institutions': institutions.join(','),
        'search_engine': searchEngine,
        'created_at': createdAt.toIso8601String(),
        'result_count': resultCount,
      };

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    final fileTypesStr = json['file_types'] as String? ?? '';
    final institutionsStr = json['institutions'] as String? ?? '';

    return SearchHistory(
      id: json['id'] as String,
      queryTerms: json['query_terms'] as String,
      fileTypes: fileTypesStr.isEmpty ? [] : fileTypesStr.split(','),
      timeRange: json['time_range'] as String? ?? 'lastWeek',
      institutions:
          institutionsStr.isEmpty ? [] : institutionsStr.split(','),
      searchEngine: json['search_engine'] as String? ?? 'google',
      createdAt: DateTime.parse(json['created_at'] as String),
      resultCount: json['result_count'] as int? ?? 0,
    );
  }

  factory SearchHistory.fromQuery(String id, SearchQuery query, int resultCount) {
    return SearchHistory(
      id: id,
      queryTerms: query.terms,
      fileTypes: query.fileTypes.map((t) => t.extension).toList(),
      timeRange: query.timeRange.name,
      institutions: query.institutions.map((i) => i.id).toList(),
      searchEngine: query.engine.code,
      createdAt: DateTime.now(),
      resultCount: resultCount,
    );
  }

  SearchHistory copyWith({
    String? id,
    String? queryTerms,
    List<String>? fileTypes,
    String? timeRange,
    List<String>? institutions,
    String? searchEngine,
    DateTime? createdAt,
    int? resultCount,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      queryTerms: queryTerms ?? this.queryTerms,
      fileTypes: fileTypes ?? this.fileTypes,
      timeRange: timeRange ?? this.timeRange,
      institutions: institutions ?? this.institutions,
      searchEngine: searchEngine ?? this.searchEngine,
      createdAt: createdAt ?? this.createdAt,
      resultCount: resultCount ?? this.resultCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
