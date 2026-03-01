import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'services.dart';
import '../models/models.dart';

/// MCP Tool definition
class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<dynamic> Function(Map<String, dynamic> args) handler;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

/// Dart-native MCP Server implementing JSON-RPC 2.0 over HTTP
class McpServer extends ChangeNotifier {
  static final McpServer _instance = McpServer._internal();
  factory McpServer() => _instance;
  McpServer._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final SettingsService _settings = SettingsService();
  final DownloadService _downloads = DownloadService();
  final SearchService _search = SearchService();
  final LibraryService _library = LibraryService();
  final ArchiveDownloadService _archives = ArchiveDownloadService();

  HttpServer? _server;
  String _host = '127.0.0.1';
  int _port = 8088;
  bool _isRunning = false;
  DateTime? _startedAt;
  int _requestCount = 0;
  final List<String> _recentLogs = [];

  // Getters
  bool get isRunning => _isRunning;
  String get host => _host;
  int get port => _port;
  String get address => 'http://$_host:$_port';
  DateTime? get startedAt => _startedAt;
  int get requestCount => _requestCount;
  List<String> get recentLogs => List.unmodifiable(_recentLogs);
  Duration? get uptime => _startedAt != null ? DateTime.now().difference(_startedAt!) : null;

  // Tool definitions
  List<McpTool>? _tools;

  void _initializeTools() {
    _tools = [
      // Health & Status
      McpTool(
        name: 'zeph_health_check',
        description: 'Check if Zephaniah is running and healthy',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async => {
          'status': 'healthy',
          'version': '1.1.0',
          'uptime_seconds': uptime?.inSeconds ?? 0,
          'request_count': _requestCount,
        },
      ),

      McpTool(
        name: 'zeph_system_info',
        description: 'Get system and app information',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async {
          final stats = _library.getStats();
          return {
            'app_version': '1.1.0',
            'platform': Platform.operatingSystem,
            'library_files': stats.totalFiles,
            'library_size_bytes': stats.totalSize,
            'library_size_formatted': stats.sizeFormatted,
            'datasets_count': _library.datasets.length,
            'active_downloads': _downloads.activeCount,
            'queued_downloads': _downloads.queuedCount,
          };
        },
      ),

      // Library Management
      McpTool(
        name: 'zeph_list_datasets',
        description: 'List all available archive datasets with status',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async {
          final datasets = <Map<String, dynamic>>[];
          for (final dataset in Datasets.all) {
            final status = await _archives.getDatasetStatus(dataset.name);
            datasets.add({
              'name': dataset.name,
              'number': dataset.number,
              'size_bytes': dataset.sizeBytes,
              'size_formatted': dataset.sizeFormatted,
              'has_zip': dataset.zipUrl != null,
              'has_magnet': dataset.magnetUri != null,
              'is_extracted': status.isExtracted,
              'is_downloading': status.isDownloading,
              'file_count': status.fileCount,
            });
          }
          return {'datasets': datasets, 'total': datasets.length};
        },
      ),

      McpTool(
        name: 'zeph_get_library_stats',
        description: 'Get library statistics including file counts by type',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async {
          final stats = _library.getStats();
          return {
            'total_files': stats.totalFiles,
            'total_size_bytes': stats.totalSize,
            'total_size_formatted': stats.sizeFormatted,
            'type_counts': stats.typeCounts,
            'datasets': _library.datasets.values
                .map((d) => {'name': d.name, 'file_count': d.fileCount, 'size_bytes': d.totalSize})
                .toList(),
          };
        },
      ),

      McpTool(
        name: 'zeph_search_library',
        description: 'Search files in the library by filename',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': 'Search query for filename'},
            'file_type': {'type': 'string', 'description': 'Filter by type (pdf, image, video, audio, document)'},
            'dataset': {'type': 'string', 'description': 'Filter by dataset name'},
            'limit': {'type': 'integer', 'description': 'Max results to return', 'default': 50},
          },
        },
        handler: (args) async {
          final query = args['query'] as String? ?? '';
          final fileType = args['file_type'] as String?;
          final dataset = args['dataset'] as String?;
          final limit = args['limit'] as int? ?? 50;

          // Apply filters
          _library.setSearchQuery(query);
          _library.setTypeFilter(fileType);
          _library.setDatasetFilter(dataset);

          final files = _library.files.take(limit).map((f) => {
                'filename': f.filename,
                'path': f.path,
                'file_type': f.fileType,
                'size_bytes': f.size,
                'size_formatted': f.sizeFormatted,
                'dataset': f.dataset,
              }).toList();

          // Clear filters after search
          _library.clearFilters();

          return {'files': files, 'count': files.length, 'query': query};
        },
      ),

      // Archive Downloads
      McpTool(
        name: 'zeph_download_archive',
        description: 'Start downloading an archive dataset by name or number',
        inputSchema: {
          'type': 'object',
          'properties': {
            'dataset': {'type': 'string', 'description': 'Dataset name (e.g., "DataSet 1") or number (e.g., "1")'},
          },
          'required': ['dataset'],
        },
        handler: (args) async {
          final datasetArg = args['dataset'] as String;

          // Find dataset by name or number
          Dataset? dataset;
          final num = int.tryParse(datasetArg);
          if (num != null) {
            dataset = Datasets.all.where((d) => d.number == num).firstOrNull;
          }
          dataset ??= Datasets.all.where((d) => d.name.toLowerCase() == datasetArg.toLowerCase()).firstOrNull;

          if (dataset == null) {
            return {'error': 'Dataset not found: $datasetArg', 'available': Datasets.all.map((d) => d.name).toList()};
          }

          if (dataset.zipUrl == null) {
            return {'error': 'Dataset requires torrent download (no ZIP URL)', 'name': dataset.name, 'magnet': dataset.magnetUri};
          }

          await _archives.startDownload(
            datasetName: dataset.name,
            url: dataset.zipUrl!,
            expectedSize: dataset.sizeBytes,
          );

          return {
            'status': 'started',
            'dataset': dataset.name,
            'size_formatted': dataset.sizeFormatted,
            'url': dataset.zipUrl,
          };
        },
      ),

      McpTool(
        name: 'zeph_get_archive_status',
        description: 'Get download/extraction status for a dataset',
        inputSchema: {
          'type': 'object',
          'properties': {
            'dataset': {'type': 'string', 'description': 'Dataset name'},
          },
          'required': ['dataset'],
        },
        handler: (args) async {
          final datasetName = args['dataset'] as String;
          final status = await _archives.getDatasetStatus(datasetName);
          final progress = _archives.getProgress(datasetName);

          return {
            'dataset': datasetName,
            'is_extracted': status.isExtracted,
            'is_downloading': status.isDownloading,
            'file_count': status.fileCount,
            'progress': progress?.progress ?? 0.0,
            'status_text': progress?.statusText ?? 'idle',
            'downloaded_bytes': progress?.bytesReceived ?? 0,
            'total_bytes': progress?.totalBytes ?? 0,
          };
        },
      ),

      // Search Operations
      McpTool(
        name: 'zeph_search_online',
        description: 'Search for documents online using configured search providers',
        inputSchema: {
          'type': 'object',
          'properties': {
            'terms': {'type': 'string', 'description': 'Search terms'},
            'engine': {'type': 'string', 'enum': ['duckduckgo', 'google', 'bing'], 'description': 'Search engine'},
            'file_types': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'File types to search for (pdf, doc, xls, etc.)'
            },
            'time_range': {'type': 'string', 'enum': ['any', 'lastDay', 'lastWeek', 'lastMonth', 'lastYear']},
          },
          'required': ['terms'],
        },
        handler: (args) async {
          final terms = args['terms'] as String;
          final engine = args['engine'] as String? ?? 'duckduckgo';
          final fileTypes = (args['file_types'] as List<dynamic>?)?.cast<String>() ?? ['pdf'];
          final timeRangeInput =
              args['time_range'] as String? ?? TimeRange.anytime.name;
          final timeRangeValue = timeRangeInput == 'any'
              ? TimeRange.anytime.name
              : timeRangeInput;

          final query = SearchQuery(
            terms: terms,
            fileTypes: fileTypes.map((t) => FileType.values.firstWhere((ft) => ft.extension == t, orElse: () => FileType.pdf)).toList(),
            timeRange: TimeRange.values.firstWhere((t) => t.name == timeRangeValue, orElse: () => TimeRange.anytime),
            engine: SearchEngine.values.firstWhere((e) => e.code == engine, orElse: () => SearchEngine.duckduckgo),
          );

          final results = await _search.search(query, page: 1);

          return {
            'query': terms,
            'engine': engine,
            'total_results': results.totalResults,
            'results': results.results.take(20).map((r) => {
                  'title': r.title,
                  'url': r.url,
                  'snippet': r.snippet,
                  'file_type': r.fileType?.extension,
                  'source': r.sourceDomain,
                }).toList(),
          };
        },
      ),

      // Download Queue
      McpTool(
        name: 'zeph_enqueue_download',
        description: 'Add a URL to the download queue',
        inputSchema: {
          'type': 'object',
          'properties': {
            'url': {'type': 'string', 'description': 'URL to download'},
            'title': {'type': 'string', 'description': 'Title/filename for the download'},
          },
          'required': ['url'],
        },
        handler: (args) async {
          final url = args['url'] as String;
          final title = args['title'] as String? ?? url.split('/').last;

          final result = SearchResult(
            id: 'mcp_${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            url: url,
            snippet: 'Manual download via MCP',
            sourceDomain: Uri.tryParse(url)?.host ?? 'unknown',
            fileType: FileType.pdf,
          );

          try {
            final task = await _downloads.enqueue(result);
            return {
              'status': 'queued',
              'task_id': task.id,
              'url': url,
              'destination': task.destinationPath,
            };
          } on DuplicateDownloadException catch (e) {
            return {'status': 'duplicate', 'message': e.message};
          }
        },
      ),

      McpTool(
        name: 'zeph_get_download_status',
        description: 'Get status of download queue',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async => {
          'active_count': _downloads.activeCount,
          'queued_count': _downloads.queuedCount,
          'completed_count': _downloads.completedCount,
          'failed_count': _downloads.failedCount,
          'active': _downloads.active.map((t) => {
                'id': t.id,
                'title': t.source.title,
                'progress': t.progress,
                'bytes_received': t.bytesReceived,
                'total_bytes': t.totalBytes,
              }).toList(),
          'queue': _downloads.queue.where((t) => t.status == DownloadStatus.queued).map((t) => {
                'id': t.id,
                'title': t.source.title,
              }).toList(),
        },
      ),

      // Database Queries
      McpTool(
        name: 'zeph_get_search_history',
        description: 'Get recent search history',
        inputSchema: {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer', 'description': 'Max entries to return', 'default': 20},
          },
        },
        handler: (args) async {
          final limit = args['limit'] as int? ?? 20;
          final searches = await _db.getSearches(limit: limit);
          return {
            'searches': searches.map((s) => {
                  'id': s.id,
                  'terms': s.queryTerms,
                  'engine': s.searchEngine,
                  'result_count': s.resultCount,
                  'created_at': s.createdAt.toIso8601String(),
                }).toList(),
            'count': searches.length,
          };
        },
      ),

      McpTool(
        name: 'zeph_get_artifacts',
        description: 'Get downloaded artifacts from database',
        inputSchema: {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer', 'description': 'Max entries to return', 'default': 50},
            'file_type': {'type': 'string', 'description': 'Filter by file type'},
          },
        },
        handler: (args) async {
          final limit = args['limit'] as int? ?? 50;
          final fileType = args['file_type'] as String?;

          FileType? type;
          if (fileType != null) {
            type = FileType.values.where((t) => t.extension == fileType).firstOrNull;
          }

          final artifacts = await _db.getArtifacts(limit: limit, fileType: type);
          return {
            'artifacts': artifacts.map((a) => {
                  'id': a.id,
                  'filename': a.filename,
                  'url': a.originalUrl,
                  'file_type': a.fileType?.extension,
                  'file_size': a.fileSize,
                  'status': a.status.name,
                  'downloaded_at': a.downloadedAt.toIso8601String(),
                }).toList(),
            'count': artifacts.length,
          };
        },
      ),

      // Settings
      McpTool(
        name: 'zeph_get_settings',
        description: 'Get current app settings',
        inputSchema: {'type': 'object', 'properties': {}},
        handler: (_) async {
          final s = _settings.settings;
          return {
            'default_search_terms': s.defaultSearchTerms,
            'default_search_engine': s.defaultSearchEngine,
            'default_file_types': s.defaultFileTypes,
            'concurrent_downloads': s.concurrentDownloads,
            'auto_retry_attempts': s.autoRetryAttempts,
            'download_location': s.downloadLocation,
            'snapshot_retention_days': s.snapshotRetentionDays,
            'show_download_queue': s.showDownloadQueue,
            'show_logs_panel': s.showLogsPanel,
          };
        },
      ),

      McpTool(
        name: 'zeph_update_settings',
        description: 'Update app settings',
        inputSchema: {
          'type': 'object',
          'properties': {
            'concurrent_downloads': {'type': 'integer', 'minimum': 1, 'maximum': 10},
            'auto_retry_attempts': {'type': 'integer', 'minimum': 0, 'maximum': 5},
            'default_search_terms': {'type': 'string'},
            'default_search_engine': {'type': 'string', 'enum': ['duckduckgo', 'google', 'bing']},
          },
        },
        handler: (args) async {
          var s = _settings.settings;

          if (args['concurrent_downloads'] != null) {
            s = s.copyWith(concurrentDownloads: args['concurrent_downloads'] as int);
          }
          if (args['auto_retry_attempts'] != null) {
            s = s.copyWith(autoRetryAttempts: args['auto_retry_attempts'] as int);
          }
          if (args['default_search_terms'] != null) {
            s = s.copyWith(defaultSearchTerms: args['default_search_terms'] as String);
          }
          if (args['default_search_engine'] != null) {
            s = s.copyWith(defaultSearchEngine: args['default_search_engine'] as String);
          }

          await _settings.update(s);
          return {'status': 'updated', 'settings': s.toJson()};
        },
      ),

      // Logs
      McpTool(
        name: 'zeph_get_logs',
        description: 'Get recent application logs',
        inputSchema: {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer', 'description': 'Max log entries', 'default': 50},
            'level': {'type': 'string', 'enum': ['debug', 'info', 'warning', 'error']},
          },
        },
        handler: (args) async {
          final limit = args['limit'] as int? ?? 50;
          final levelStr = args['level'] as String?;

          var entries = _log.entries;
          if (levelStr != null) {
            final level = LogLevel.values.firstWhere((l) => l.name == levelStr, orElse: () => LogLevel.info);
            entries = _log.filterByLevel(level);
          }

          return {
            'logs': entries.take(limit).map((e) => {
                  'timestamp': e.timestamp.toIso8601String(),
                  'level': e.level.name,
                  'source': e.source,
                  'message': e.message,
                }).toList(),
            'count': entries.length,
          };
        },
      ),
    ];
  }

  List<McpTool> get tools {
    if (_tools == null) _initializeTools();
    return _tools!;
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _recentLogs.add('[$timestamp] $message');
    if (_recentLogs.length > 100) {
      _recentLogs.removeAt(0);
    }
    notifyListeners();
  }

  Future<bool> start({String? host, int? port}) async {
    if (_isRunning) return true;

    _host = host ?? _host;
    _port = port ?? _port;

    try {
      _initializeTools();
      _server = await HttpServer.bind(_host, _port);
      _isRunning = true;
      _startedAt = DateTime.now();
      _requestCount = 0;

      _addLog('MCP server started on $_host:$_port');
      _log.info('McpServer', 'Started on $_host:$_port with ${tools.length} tools');
      notifyListeners();

      _server!.listen(_handleRequest);
      return true;
    } catch (e) {
      _addLog('Failed to start: $e');
      _log.error('McpServer', 'Failed to start: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning || _server == null) return;

    await _server!.close(force: true);
    _server = null;
    _isRunning = false;
    _startedAt = null;

    _addLog('MCP server stopped');
    _log.info('McpServer', 'Stopped');
    notifyListeners();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _requestCount++;

    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    request.response.headers.contentType = ContentType.json;

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    if (request.method != 'POST') {
      await _sendError(request, -32600, 'Only POST method allowed');
      return;
    }

    try {
      final body = await utf8.decoder.bind(request).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final method = json['method'] as String?;
      final params = json['params'] as Map<String, dynamic>? ?? {};
      final id = json['id'];

      _addLog('$method (id: $id)');

      dynamic result;
      if (method == 'initialize') {
        result = {
          'protocolVersion': '2024-11-05',
          'serverInfo': {'name': 'zephaniah-mcp', 'version': '1.1.0'},
          'capabilities': {'tools': {}},
        };
      } else if (method == 'tools/list' || method == 'tools.list') {
        result = {'tools': tools.map((t) => t.toJson()).toList()};
      } else if (method == 'tools/call' || method == 'tools.call') {
        final toolName = params['name'] as String?;
        final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

        final tool = tools.where((t) => t.name == toolName).firstOrNull;
        if (tool == null) {
          await _sendError(request, -32601, 'Unknown tool: $toolName', id);
          return;
        }

        final toolResult = await tool.handler(arguments);
        result = {
          'content': [
            {'type': 'text', 'text': jsonEncode(toolResult)}
          ]
        };
      } else {
        await _sendError(request, -32601, 'Unknown method: $method', id);
        return;
      }

      await _sendResponse(request, result, id);
    } catch (e, stack) {
      _addLog('Error: $e');
      _log.error('McpServer', 'Request error: $e\n$stack');
      await _sendError(request, -32603, 'Internal error: $e');
    }
  }

  Future<void> _sendResponse(HttpRequest request, dynamic result, dynamic id) async {
    final response = {'jsonrpc': '2.0', 'result': result, 'id': id};
    request.response.write(jsonEncode(response));
    await request.response.close();
  }

  Future<void> _sendError(HttpRequest request, int code, String message, [dynamic id]) async {
    final response = {
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message},
      'id': id,
    };
    request.response.write(jsonEncode(response));
    await request.response.close();
  }

  /// Generate Claude Code configuration JSON
  String generateClaudeConfig() {
    return '''
{
  "mcpServers": {
    "zephaniah": {
      "url": "http://$_host:$_port"
    }
  }
}''';
  }
}
