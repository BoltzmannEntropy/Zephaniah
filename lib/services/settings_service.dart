import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class AppSettings {
  // Search defaults
  final String defaultSearchTerms;
  final List<String> defaultFileTypes;
  final String defaultTimeRange;
  final String defaultSearchEngine;
  final List<String> defaultInstitutions;

  // Download settings
  final int concurrentDownloads;
  final int autoRetryAttempts;
  final String downloadLocation;

  // Snapshot settings
  final bool autoRunOnLaunch;
  final int snapshotRetentionDays;

  // UI settings
  final bool showLogsPanel;
  final bool showDownloadQueue;

  const AppSettings({
    this.defaultSearchTerms = 'Jeffrey Epstein',
    this.defaultFileTypes = const ['pdf'],
    this.defaultTimeRange = 'lastWeek',
    this.defaultSearchEngine = 'google',
    this.defaultInstitutions = const [],
    this.concurrentDownloads = 3,
    this.autoRetryAttempts = 2,
    this.downloadLocation = '',
    this.autoRunOnLaunch = false,
    this.snapshotRetentionDays = 30,
    this.showLogsPanel = true,
    this.showDownloadQueue = true,
  });

  Map<String, dynamic> toJson() => {
        'default_search_terms': defaultSearchTerms,
        'default_file_types': defaultFileTypes,
        'default_time_range': defaultTimeRange,
        'default_search_engine': defaultSearchEngine,
        'default_institutions': defaultInstitutions,
        'concurrent_downloads': concurrentDownloads,
        'auto_retry_attempts': autoRetryAttempts,
        'download_location': downloadLocation,
        'auto_run_on_launch': autoRunOnLaunch,
        'snapshot_retention_days': snapshotRetentionDays,
        'show_logs_panel': showLogsPanel,
        'show_download_queue': showDownloadQueue,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      final lower = value?.toString().toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      return fallback;
    }

    List<String> parseStringList(dynamic value, List<String> fallback) {
      if (value is List) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
      return fallback;
    }

    return AppSettings(
      defaultSearchTerms:
          json['default_search_terms'] as String? ?? 'Jeffrey Epstein',
      defaultFileTypes: parseStringList(json['default_file_types'], const ['pdf']),
      defaultTimeRange: json['default_time_range'] as String? ?? 'lastWeek',
      defaultSearchEngine:
          json['default_search_engine'] as String? ?? 'google',
      defaultInstitutions: parseStringList(json['default_institutions'], const []),
      concurrentDownloads: parseInt(json['concurrent_downloads'], 3),
      autoRetryAttempts: parseInt(json['auto_retry_attempts'], 2),
      downloadLocation: json['download_location'] as String? ?? '',
      autoRunOnLaunch: parseBool(json['auto_run_on_launch'], false),
      snapshotRetentionDays: parseInt(json['snapshot_retention_days'], 30),
      showLogsPanel: parseBool(json['show_logs_panel'], true),
      showDownloadQueue: parseBool(json['show_download_queue'], true),
    );
  }

  AppSettings copyWith({
    String? defaultSearchTerms,
    List<String>? defaultFileTypes,
    String? defaultTimeRange,
    String? defaultSearchEngine,
    List<String>? defaultInstitutions,
    int? concurrentDownloads,
    int? autoRetryAttempts,
    String? downloadLocation,
    bool? autoRunOnLaunch,
    int? snapshotRetentionDays,
    bool? showLogsPanel,
    bool? showDownloadQueue,
  }) {
    return AppSettings(
      defaultSearchTerms: defaultSearchTerms ?? this.defaultSearchTerms,
      defaultFileTypes: defaultFileTypes ?? this.defaultFileTypes,
      defaultTimeRange: defaultTimeRange ?? this.defaultTimeRange,
      defaultSearchEngine: defaultSearchEngine ?? this.defaultSearchEngine,
      defaultInstitutions: defaultInstitutions ?? this.defaultInstitutions,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      autoRetryAttempts: autoRetryAttempts ?? this.autoRetryAttempts,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      autoRunOnLaunch: autoRunOnLaunch ?? this.autoRunOnLaunch,
      snapshotRetentionDays:
          snapshotRetentionDays ?? this.snapshotRetentionDays,
      showLogsPanel: showLogsPanel ?? this.showLogsPanel,
      showDownloadQueue: showDownloadQueue ?? this.showDownloadQueue,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  AppSettings _settings = const AppSettings();
  File? _settingsFile;
  String _appDir = '';
  bool _initialized = false;

  AppSettings get settings => _settings;
  String get appDir => _appDir;
  String get artifactsDir => '$_appDir/artifacts';
  String get databaseDir => '$_appDir/database';
  String get logsDir => '$_appDir/logs';

  Future<void> initialize() async {
    if (_initialized) return;
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    _appDir = '${baseDir.path}/Zephaniah';

    // Create directories
    await _ensureDir(artifactsDir);
    await _ensureDir(databaseDir);
    await _ensureDir(logsDir);

    // Load settings
    _settingsFile = File('$_appDir/settings.json');
    await _load();
    _initialized = true;
  }

  Future<void> _ensureDir(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  AppSettings _sanitizeSettings(AppSettings value) {
    final validFileTypes = value.defaultFileTypes
        .where((t) => FileType.fromExtension(t) != null)
        .toList(growable: false);
    final validTimeRange = TimeRange.values.any((t) => t.name == value.defaultTimeRange)
        ? value.defaultTimeRange
        : TimeRange.lastWeek.name;
    final validEngine = SearchEngine.values.any((e) => e.code == value.defaultSearchEngine)
        ? value.defaultSearchEngine
        : SearchEngine.duckduckgo.code;
    final safeConcurrent = value.concurrentDownloads.clamp(1, 8);
    final safeRetries = value.autoRetryAttempts.clamp(0, 5);
    final safeRetention = value.snapshotRetentionDays.clamp(1, 3650);

    var resolvedDownloadLocation = value.downloadLocation.trim();
    if (resolvedDownloadLocation.isEmpty) {
      resolvedDownloadLocation = artifactsDir;
    } else {
      resolvedDownloadLocation = Directory(resolvedDownloadLocation).absolute.path;
    }

    return value.copyWith(
      defaultFileTypes: validFileTypes.isEmpty ? const ['pdf'] : validFileTypes,
      defaultTimeRange: validTimeRange,
      defaultSearchEngine: validEngine,
      concurrentDownloads: safeConcurrent,
      autoRetryAttempts: safeRetries,
      snapshotRetentionDays: safeRetention,
      downloadLocation: resolvedDownloadLocation,
    );
  }

  Future<void> _load() async {
    if (_settingsFile == null || !await _settingsFile!.exists()) {
      _settings = AppSettings(downloadLocation: artifactsDir);
      await _save();
      return;
    }

    try {
      final content = await _settingsFile!.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Settings JSON must be an object');
      }
      _settings = _sanitizeSettings(AppSettings.fromJson(decoded));
      await _ensureDir(_settings.downloadLocation);
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      _settings = AppSettings(downloadLocation: artifactsDir);
      try {
        if (_settingsFile != null && await _settingsFile!.exists()) {
          await _settingsFile!.rename('${_settingsFile!.path}.corrupt');
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    if (_settingsFile == null) return;
    try {
      final json = jsonEncode(_settings.toJson());
      final tempFile = File('${_settingsFile!.path}.tmp');
      await tempFile.writeAsString(json, flush: true);
      if (await _settingsFile!.exists()) {
        await _settingsFile!.delete();
      }
      await tempFile.rename(_settingsFile!.path);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = _sanitizeSettings(newSettings);
    await _ensureDir(_settings.downloadLocation);
    await _save();
    notifyListeners();
  }

  Future<void> updateSearchDefaults({
    String? terms,
    List<FileType>? fileTypes,
    TimeRange? timeRange,
    SearchEngine? engine,
    List<Institution>? institutions,
  }) async {
    _settings = _sanitizeSettings(_settings.copyWith(
      defaultSearchTerms: terms,
      defaultFileTypes: fileTypes?.map((t) => t.extension).toList(),
      defaultTimeRange: timeRange?.name,
      defaultSearchEngine: engine?.code,
      defaultInstitutions: institutions?.map((i) => i.id).toList(),
    ));
    await _save();
    notifyListeners();
  }

  Future<void> updateDownloadSettings({
    int? concurrentDownloads,
    int? autoRetryAttempts,
    String? downloadLocation,
  }) async {
    _settings = _sanitizeSettings(_settings.copyWith(
      concurrentDownloads: concurrentDownloads,
      autoRetryAttempts: autoRetryAttempts,
      downloadLocation: downloadLocation,
    ));
    await _ensureDir(_settings.downloadLocation);
    await _save();
    notifyListeners();
  }

  Future<void> updateSnapshotSettings({
    bool? autoRunOnLaunch,
    int? snapshotRetentionDays,
  }) async {
    _settings = _sanitizeSettings(_settings.copyWith(
      autoRunOnLaunch: autoRunOnLaunch,
      snapshotRetentionDays: snapshotRetentionDays,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> updateUISettings({
    bool? showLogsPanel,
    bool? showDownloadQueue,
  }) async {
    _settings = _sanitizeSettings(_settings.copyWith(
      showLogsPanel: showLogsPanel,
      showDownloadQueue: showDownloadQueue,
    ));
    await _save();
    notifyListeners();
  }

  String getArtifactPath(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${_settings.downloadLocation}/$dateStr';
  }

  Future<void> reset() async {
    _settings = _sanitizeSettings(AppSettings(downloadLocation: artifactsDir));
    await _save();
    notifyListeners();
  }
}
