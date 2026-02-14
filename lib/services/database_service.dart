import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import 'settings_service.dart';
import 'log_service.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  bool _initialized = false;
  final LogService _log = LogService();

  Database get db {
    if (_db == null) throw Exception('Database not initialized');
    return _db!;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final settings = SettingsService();
    final dbPath = path.join(settings.databaseDir, 'zephaniah.db');

    try {
      _db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      _initialized = true;
      _log.info('DatabaseService', 'Database initialized at $dbPath');
    } catch (e) {
      _log.error(
        'DatabaseService',
        'Primary DB open failed, using in-memory fallback: $e',
      );
      _db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      _initialized = true;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE searches (
        id TEXT PRIMARY KEY,
        query_terms TEXT NOT NULL,
        file_types TEXT,
        time_range TEXT,
        institutions TEXT,
        search_engine TEXT,
        created_at TEXT NOT NULL,
        result_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE artifacts (
        id TEXT PRIMARY KEY,
        search_id TEXT,
        filename TEXT NOT NULL,
        original_url TEXT NOT NULL,
        source_institution TEXT,
        file_type TEXT,
        file_size INTEGER,
        file_path TEXT NOT NULL,
        downloaded_at TEXT NOT NULL,
        status TEXT DEFAULT 'completed',
        error_message TEXT,
        metadata_json TEXT,
        FOREIGN KEY (search_id) REFERENCES searches(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE snapshots (
        id TEXT PRIMARY KEY,
        snapshot_date TEXT NOT NULL,
        search_terms TEXT,
        institutions_used TEXT,
        artifacts_found INTEGER DEFAULT 0,
        artifacts_downloaded INTEGER DEFAULT 0,
        new_artifacts INTEGER DEFAULT 0,
        duplicates_skipped INTEGER DEFAULT 0,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT DEFAULT 'running',
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_institutions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url_pattern TEXT NOT NULL,
        color_hex TEXT,
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mcp_providers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        endpoint_url TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        config_json TEXT,
        added_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_artifacts_search_id ON artifacts(search_id)');
    await db.execute(
        'CREATE INDEX idx_artifacts_downloaded_at ON artifacts(downloaded_at)');
    await db.execute(
        'CREATE INDEX idx_searches_created_at ON searches(created_at)');
    await db.execute(
        'CREATE INDEX idx_snapshots_snapshot_date ON snapshots(snapshot_date)');

    _log.info('DatabaseService', 'Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _log.info('DatabaseService',
        'Database upgrade from $oldVersion to $newVersion');
  }

  @override
  void dispose() {
    final database = _db;
    _db = null;
    _initialized = false;
    database?.close();
    super.dispose();
  }

  // Search History CRUD
  Future<void> insertSearch(SearchHistory search) async {
    await db.insert('searches', search.toJson());
    notifyListeners();
  }

  Future<List<SearchHistory>> getSearches({int limit = 50}) async {
    final results = await db.query(
      'searches',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((r) => SearchHistory.fromJson(r)).toList();
  }

  Future<SearchHistory?> getSearch(String id) async {
    final results = await db.query(
      'searches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SearchHistory.fromJson(results.first);
  }

  Future<void> deleteSearch(String id) async {
    await db.delete('searches', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  // Artifacts CRUD
  Future<void> insertArtifact(Artifact artifact) async {
    await db.insert('artifacts', artifact.toJson());
    notifyListeners();
  }

  Future<void> updateArtifact(Artifact artifact) async {
    await db.update(
      'artifacts',
      artifact.toJson(),
      where: 'id = ?',
      whereArgs: [artifact.id],
    );
    notifyListeners();
  }

  Future<List<Artifact>> getArtifacts({
    String? searchId,
    DateTime? date,
    FileType? fileType,
    int limit = 100,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (searchId != null) {
      where = 'search_id = ?';
      whereArgs = [searchId];
    } else if (date != null) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      where = 'downloaded_at LIKE ?';
      whereArgs = ['$dateStr%'];
    }

    if (fileType != null) {
      final typeWhere = 'file_type = ?';
      if (where != null) {
        where = '$where AND $typeWhere';
        whereArgs!.add(fileType.extension);
      } else {
        where = typeWhere;
        whereArgs = [fileType.extension];
      }
    }

    final results = await db.query(
      'artifacts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'downloaded_at DESC',
      limit: limit,
    );
    return results.map((r) => Artifact.fromJson(r)).toList();
  }

  Future<Artifact?> getArtifact(String id) async {
    final results = await db.query(
      'artifacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Artifact.fromJson(results.first);
  }

  Future<Artifact?> getArtifactByUrl(String url) async {
    final results = await db.query(
      'artifacts',
      where: 'original_url = ?',
      whereArgs: [url],
    );
    if (results.isEmpty) return null;
    return Artifact.fromJson(results.first);
  }

  Future<List<Artifact>> getArtifactsBySearch(String searchId) async {
    final results = await db.query(
      'artifacts',
      where: 'search_id = ?',
      whereArgs: [searchId],
      orderBy: 'downloaded_at DESC',
    );
    return results.map((r) => Artifact.fromJson(r)).toList();
  }

  Future<void> deleteArtifact(String id) async {
    await db.delete('artifacts', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<int> getArtifactCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM artifacts');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getTotalArtifactSize() async {
    final result = await db.rawQuery(
        'SELECT SUM(file_size) as total FROM artifacts WHERE file_size IS NOT NULL');
    return result.first['total'] as int? ?? 0;
  }

  // Snapshots CRUD
  Future<void> insertSnapshot(Snapshot snapshot) async {
    await db.insert('snapshots', snapshot.toJson());
    notifyListeners();
  }

  Future<void> updateSnapshot(Snapshot snapshot) async {
    await db.update(
      'snapshots',
      snapshot.toJson(),
      where: 'id = ?',
      whereArgs: [snapshot.id],
    );
    notifyListeners();
  }

  Future<List<Snapshot>> getSnapshots({int limit = 50}) async {
    final results = await db.query(
      'snapshots',
      orderBy: 'snapshot_date DESC',
      limit: limit,
    );
    return results.map((r) => Snapshot.fromJson(r)).toList();
  }

  Future<Snapshot?> getSnapshot(String id) async {
    final results = await db.query(
      'snapshots',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Snapshot.fromJson(results.first);
  }

  Future<Snapshot?> getSnapshotByDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final results = await db.query(
      'snapshots',
      where: 'snapshot_date LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    if (results.isEmpty) return null;
    return Snapshot.fromJson(results.first);
  }

  Future<void> deleteSnapshot(String id) async {
    await db.delete('snapshots', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  // Custom Institutions CRUD
  Future<void> insertCustomInstitution(Institution institution) async {
    await db.insert('custom_institutions', institution.toJson());
    notifyListeners();
  }

  Future<void> updateCustomInstitution(Institution institution) async {
    await db.update(
      'custom_institutions',
      institution.toJson(),
      where: 'id = ?',
      whereArgs: [institution.id],
    );
    notifyListeners();
  }

  Future<List<Institution>> getCustomInstitutions() async {
    final results = await db.query('custom_institutions');
    return results.map((r) => Institution.fromJson(r)).toList();
  }

  Future<void> deleteCustomInstitution(String id) async {
    await db.delete('custom_institutions', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  // MCP Providers CRUD
  Future<void> insertMcpProvider(Map<String, dynamic> provider) async {
    await db.insert('mcp_providers', provider);
    notifyListeners();
  }

  Future<void> updateMcpProvider(Map<String, dynamic> provider) async {
    await db.update(
      'mcp_providers',
      provider,
      where: 'id = ?',
      whereArgs: [provider['id']],
    );
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMcpProviders() async {
    return await db.query('mcp_providers');
  }

  Future<void> deleteMcpProvider(String id) async {
    await db.delete('mcp_providers', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  // Cleanup
  Future<void> cleanupOldArtifacts(int retentionDays) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();
    await db.delete(
      'artifacts',
      where: 'downloaded_at < ?',
      whereArgs: [cutoff],
    );
    notifyListeners();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
