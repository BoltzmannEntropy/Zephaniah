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
    return AppSettings(
      defaultSearchTerms:
          json['default_search_terms'] as String? ?? 'Jeffrey Epstein',
      defaultFileTypes: (json['default_file_types'] as List?)
              ?.cast<String>() ??
          const ['pdf'],
      defaultTimeRange: json['default_time_range'] as String? ?? 'lastWeek',
      defaultSearchEngine:
          json['default_search_engine'] as String? ?? 'google',
      defaultInstitutions: (json['default_institutions'] as List?)
              ?.cast<String>() ??
          const [],
      concurrentDownloads: json['concurrent_downloads'] as int? ?? 3,
      autoRetryAttempts: json['auto_retry_attempts'] as int? ?? 2,
      downloadLocation: json['download_location'] as String? ?? '',
      autoRunOnLaunch: json['auto_run_on_launch'] as bool? ?? false,
      snapshotRetentionDays: json['snapshot_retention_days'] as int? ?? 30,
      showLogsPanel: json['show_logs_panel'] as bool? ?? true,
      showDownloadQueue: json['show_download_queue'] as bool? ?? true,
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

  AppSettings get settings => _settings;
  String get appDir => _appDir;
  String get artifactsDir => '$_appDir/artifacts';
  String get databaseDir => '$_appDir/database';
  String get logsDir => '$_appDir/logs';

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _appDir = '${dir.path}/Zephaniah';

    // Create directories
    await Directory(artifactsDir).create(recursive: true);
    await Directory(databaseDir).create(recursive: true);
    await Directory(logsDir).create(recursive: true);

    // Load settings
    _settingsFile = File('$_appDir/settings.json');
    await _load();
  }

  Future<void> _load() async {
    if (_settingsFile == null || !await _settingsFile!.exists()) {
      _settings = AppSettings(downloadLocation: artifactsDir);
      await _save();
      return;
    }

    try {
      final content = await _settingsFile!.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _settings = AppSettings.fromJson(json);

      // Ensure download location is set
      if (_settings.downloadLocation.isEmpty) {
        _settings = _settings.copyWith(downloadLocation: artifactsDir);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      _settings = AppSettings(downloadLocation: artifactsDir);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    if (_settingsFile == null) return;
    try {
      final json = jsonEncode(_settings.toJson());
      await _settingsFile!.writeAsString(json);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
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
    _settings = _settings.copyWith(
      defaultSearchTerms: terms,
      defaultFileTypes: fileTypes?.map((t) => t.extension).toList(),
      defaultTimeRange: timeRange?.name,
      defaultSearchEngine: engine?.code,
      defaultInstitutions: institutions?.map((i) => i.id).toList(),
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateDownloadSettings({
    int? concurrentDownloads,
    int? autoRetryAttempts,
    String? downloadLocation,
  }) async {
    _settings = _settings.copyWith(
      concurrentDownloads: concurrentDownloads,
      autoRetryAttempts: autoRetryAttempts,
      downloadLocation: downloadLocation,
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateSnapshotSettings({
    bool? autoRunOnLaunch,
    int? snapshotRetentionDays,
  }) async {
    _settings = _settings.copyWith(
      autoRunOnLaunch: autoRunOnLaunch,
      snapshotRetentionDays: snapshotRetentionDays,
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateUISettings({
    bool? showLogsPanel,
    bool? showDownloadQueue,
  }) async {
    _settings = _settings.copyWith(
      showLogsPanel: showLogsPanel,
      showDownloadQueue: showDownloadQueue,
    );
    await _save();
    notifyListeners();
  }

  String getArtifactPath(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${_settings.downloadLocation}/$dateStr';
  }

  Future<void> reset() async {
    _settings = AppSettings(downloadLocation: artifactsDir);
    await _save();
    notifyListeners();
  }
}
