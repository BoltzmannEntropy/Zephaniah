import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'log_service.dart';
import 'database_service.dart';
import 'settings_service.dart';
import 'search_service.dart';
import 'download_service.dart';

class SnapshotService extends ChangeNotifier {
  static final SnapshotService _instance = SnapshotService._internal();
  factory SnapshotService() => _instance;
  SnapshotService._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final SettingsService _settings = SettingsService();
  final SearchService _search = SearchService();
  final DownloadService _download = DownloadService();
  final _uuid = const Uuid();

  Snapshot? _currentSnapshot;
  bool _isRunning = false;

  Snapshot? get currentSnapshot => _currentSnapshot;
  bool get isRunning => _isRunning;

  Future<Snapshot> runDailySnapshot({
    String? customTerms,
    List<Institution>? customInstitutions,
  }) async {
    if (_isRunning) {
      throw Exception('Snapshot already in progress');
    }

    _isRunning = true;
    notifyListeners();

    final now = DateTime.now();
    final settings = _settings.settings;

    // Build search query
    final terms = customTerms ?? settings.defaultSearchTerms;
    final institutions = customInstitutions ?? DefaultInstitutions.all;

    _currentSnapshot = Snapshot(
      id: _uuid.v4(),
      snapshotDate: now,
      searchTerms: terms,
      institutionsUsed: institutions.map((i) => i.id).toList(),
      startedAt: now,
      status: SnapshotStatus.running,
    );

    await _db.insertSnapshot(_currentSnapshot!);
    notifyListeners();

    _log.info('SnapshotService', 'Starting daily snapshot: $terms');

    try {
      var totalFound = 0;
      var totalDownloaded = 0;
      var newArtifacts = 0;
      var duplicatesSkipped = 0;

      // Search each institution
      for (final institution in institutions) {
        try {
          final query = SearchQuery(
            terms: terms,
            institutions: [institution],
            fileTypes: settings.defaultFileTypes
                .map((e) => FileType.fromExtension(e))
                .whereType<FileType>()
                .toList(),
            timeRange: TimeRange.values.firstWhere(
              (t) => t.name == settings.defaultTimeRange,
              orElse: () => TimeRange.lastWeek,
            ),
            engine: SearchEngine.values.firstWhere(
              (e) => e.code == settings.defaultSearchEngine,
              orElse: () => SearchEngine.duckduckgo,
            ),
          );

          final results = await _search.search(query);
          totalFound += results.results.length;

          _log.info('SnapshotService',
              '${institution.name}: ${results.results.length} results');

          // Download new files
          for (final result in results.results) {
            try {
              // Check if already exists
              final existing = await _db.getArtifactByUrl(result.url);
              if (existing != null) {
                duplicatesSkipped++;
                continue;
              }

              await _download.enqueue(result, searchId: _currentSnapshot!.id);
              totalDownloaded++;
              newArtifacts++;
            } catch (e) {
              duplicatesSkipped++;
            }
          }

          // Update snapshot progress
          _currentSnapshot = _currentSnapshot!.copyWith(
            artifactsFound: totalFound,
            artifactsDownloaded: totalDownloaded,
            newArtifacts: newArtifacts,
            duplicatesSkipped: duplicatesSkipped,
          );
          await _db.updateSnapshot(_currentSnapshot!);
          notifyListeners();

          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          _log.warning('SnapshotService',
              'Failed for ${institution.name}: $e');
        }
      }

      // Mark as completed
      _currentSnapshot = _currentSnapshot!.copyWith(
        status: SnapshotStatus.completed,
        completedAt: DateTime.now(),
      );
      await _db.updateSnapshot(_currentSnapshot!);

      _log.info('SnapshotService',
          'Snapshot completed: $totalFound found, $newArtifacts new, $duplicatesSkipped duplicates');

      return _currentSnapshot!;
    } catch (e) {
      _currentSnapshot = _currentSnapshot!.copyWith(
        status: SnapshotStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
      await _db.updateSnapshot(_currentSnapshot!);
      _log.error('SnapshotService', 'Snapshot failed: $e');
      rethrow;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> cancelSnapshot() async {
    if (!_isRunning || _currentSnapshot == null) return;

    _currentSnapshot = _currentSnapshot!.copyWith(
      status: SnapshotStatus.cancelled,
      completedAt: DateTime.now(),
    );
    await _db.updateSnapshot(_currentSnapshot!);

    _isRunning = false;
    _log.info('SnapshotService', 'Snapshot cancelled');
    notifyListeners();
  }

  Future<List<Snapshot>> getSnapshots({int limit = 50}) async {
    return await _db.getSnapshots(limit: limit);
  }

  Future<Snapshot?> getSnapshot(String id) async {
    return await _db.getSnapshot(id);
  }

  Future<List<Artifact>> getSnapshotArtifacts(String snapshotId) async {
    // Get artifacts downloaded during snapshot date
    final snapshot = await _db.getSnapshot(snapshotId);
    if (snapshot == null) return [];

    return await _db.getArtifacts(date: snapshot.snapshotDate);
  }
}
