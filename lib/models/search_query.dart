import 'institution.dart';

enum FileType {
  pdf('PDF', 'pdf'),
  doc('DOC', 'doc'),
  docx('DOCX', 'docx'),
  xls('XLS', 'xls'),
  xlsx('XLSX', 'xlsx'),
  ppt('PPT', 'ppt'),
  pptx('PPTX', 'pptx'),
  txt('TXT', 'txt'),
  mp3('MP3', 'mp3'),
  mp4('MP4', 'mp4'),
  wav('WAV', 'wav'),
  mov('MOV', 'mov');

  final String label;
  final String extension;

  const FileType(this.label, this.extension);

  String get fileTypeFilter => 'filetype:$extension';

  static FileType? fromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceFirst('.', '');
    for (final type in FileType.values) {
      if (type.extension == normalized) return type;
    }
    return null;
  }
}

enum TimeRange {
  anytime('Anytime', null),
  lastDay('Last 24 hours', 'd'),
  lastWeek('Last week', 'w'),
  lastMonth('Last month', 'm'),
  lastYear('Last year', 'y'),
  custom('Custom range', null);

  final String label;
  final String? googleCode;

  const TimeRange(this.label, this.googleCode);

  String? get googleParam => googleCode != null ? 'qdr:$googleCode' : null;
}

enum SearchEngine {
  google('Google', 'google'),
  bing('Bing', 'bing'),
  duckduckgo('DuckDuckGo', 'duckduckgo');

  final String label;
  final String code;

  const SearchEngine(this.label, this.code);
}

class SearchQuery {
  final String terms;
  final List<Institution> institutions;
  final List<FileType> fileTypes;
  final TimeRange timeRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final SearchEngine engine;
  final int maxResults;
  final bool fullInternetSearch; // When true, ignores institution site: filters

  const SearchQuery({
    required this.terms,
    this.institutions = const [],
    this.fileTypes = const [FileType.pdf],
    this.timeRange = TimeRange.lastWeek,
    this.customStartDate,
    this.customEndDate,
    this.engine = SearchEngine.duckduckgo,
    this.maxResults = 50,
    this.fullInternetSearch = false,
  });

  String buildQuery() {
    final parts = <String>[];

    // Add search terms, quoting multi-word terms for exact phrase matching
    if (terms.isNotEmpty) {
      final trimmedTerms = terms.trim();
      // Quote multi-word terms (contains space and not already quoted)
      if (trimmedTerms.contains(' ') && !trimmedTerms.startsWith('"')) {
        parts.add('"$trimmedTerms"');
      } else {
        parts.add(trimmedTerms);
      }
    }

    // Add site filters (only if not full internet search)
    if (!fullInternetSearch && institutions.isNotEmpty) {
      final siteFilters =
          institutions.map((i) => i.siteFilter).join(' OR ');
      if (institutions.length > 1) {
        parts.add('($siteFilters)');
      } else {
        parts.add(siteFilters);
      }
    }

    // Add file type filters
    if (fileTypes.isNotEmpty) {
      final typeFilters =
          fileTypes.map((t) => t.fileTypeFilter).join(' OR ');
      if (fileTypes.length > 1) {
        parts.add('($typeFilters)');
      } else {
        parts.add(typeFilters);
      }
    }

    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
        'terms': terms,
        'institutions': institutions.map((i) => i.id).toList(),
        'file_types': fileTypes.map((t) => t.extension).toList(),
        'time_range': timeRange.name,
        'custom_start_date': customStartDate?.toIso8601String(),
        'custom_end_date': customEndDate?.toIso8601String(),
        'engine': engine.code,
        'max_results': maxResults,
        'full_internet_search': fullInternetSearch,
      };

  factory SearchQuery.fromJson(
    Map<String, dynamic> json,
    List<Institution> allInstitutions,
  ) {
    final institutionIds = (json['institutions'] as List?)?.cast<String>() ?? [];
    final fileTypeExts = (json['file_types'] as List?)?.cast<String>() ?? [];

    return SearchQuery(
      terms: json['terms'] as String,
      institutions: allInstitutions
          .where((i) => institutionIds.contains(i.id))
          .toList(),
      fileTypes: fileTypeExts
          .map((e) => FileType.fromExtension(e))
          .whereType<FileType>()
          .toList(),
      timeRange: TimeRange.values.firstWhere(
        (t) => t.name == json['time_range'],
        orElse: () => TimeRange.lastWeek,
      ),
      customStartDate: json['custom_start_date'] != null
          ? DateTime.parse(json['custom_start_date'] as String)
          : null,
      customEndDate: json['custom_end_date'] != null
          ? DateTime.parse(json['custom_end_date'] as String)
          : null,
      engine: SearchEngine.values.firstWhere(
        (e) => e.code == json['engine'],
        orElse: () => SearchEngine.duckduckgo,
      ),
      maxResults: json['max_results'] as int? ?? 50,
      fullInternetSearch: json['full_internet_search'] as bool? ?? false,
    );
  }

  SearchQuery copyWith({
    String? terms,
    List<Institution>? institutions,
    List<FileType>? fileTypes,
    TimeRange? timeRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    SearchEngine? engine,
    int? maxResults,
    bool? fullInternetSearch,
  }) {
    return SearchQuery(
      terms: terms ?? this.terms,
      institutions: institutions ?? this.institutions,
      fileTypes: fileTypes ?? this.fileTypes,
      timeRange: timeRange ?? this.timeRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      engine: engine ?? this.engine,
      maxResults: maxResults ?? this.maxResults,
      fullInternetSearch: fullInternetSearch ?? this.fullInternetSearch,
    );
  }
}
