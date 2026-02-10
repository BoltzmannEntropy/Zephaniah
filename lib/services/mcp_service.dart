import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'log_service.dart';
import 'database_service.dart';

class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  List<String> get requiredParams {
    final required = inputSchema['required'];
    if (required is List) return required.cast<String>();
    return [];
  }

  Map<String, dynamic> get parameters {
    final props = inputSchema['properties'];
    if (props is Map<String, dynamic>) return props;
    return {};
  }

  factory McpTool.fromJson(Map<String, dynamic> json) {
    return McpTool(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      inputSchema: json['inputSchema'] as Map<String, dynamic>? ?? {},
    );
  }
}

class McpProvider {
  final String id;
  final String name;
  final String endpointUrl;
  final bool enabled;
  final Map<String, dynamic>? config;
  final DateTime addedAt;
  bool isConnected;
  String? serverName;
  String? serverVersion;
  List<McpTool> tools;

  McpProvider({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.enabled = true,
    this.config,
    required this.addedAt,
    this.isConnected = false,
    this.serverName,
    this.serverVersion,
    this.tools = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'endpoint_url': endpointUrl,
        'enabled': enabled ? 1 : 0,
        'config_json': config != null ? jsonEncode(config) : null,
        'added_at': addedAt.toIso8601String(),
      };

  factory McpProvider.fromJson(Map<String, dynamic> json) {
    return McpProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      endpointUrl: json['endpoint_url'] as String,
      enabled: (json['enabled'] as int?) == 1,
      config: json['config_json'] != null
          ? jsonDecode(json['config_json'] as String) as Map<String, dynamic>
          : null,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
}

class McpService extends ChangeNotifier {
  static final McpService _instance = McpService._internal();
  factory McpService() => _instance;
  McpService._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final List<McpProvider> _providers = [];
  Timer? _healthTimer;
  int _requestId = 0;

  List<McpProvider> get providers => List.unmodifiable(_providers);
  List<McpProvider> get enabledProviders =>
      _providers.where((p) => p.enabled).toList();
  List<McpProvider> get connectedProviders =>
      _providers.where((p) => p.isConnected).toList();

  Future<void> initialize() async {
    await _loadProviders();
    startHealthMonitor();
  }

  Future<void> _loadProviders() async {
    final records = await _db.getMcpProviders();
    _providers.clear();
    _providers.addAll(records.map((r) => McpProvider.fromJson(r)));
    _log.info('McpService', 'Loaded ${_providers.length} MCP providers');
    notifyListeners();
  }

  void startHealthMonitor({Duration interval = const Duration(seconds: 30)}) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(interval, (_) => checkAllHealth());
    checkAllHealth();
  }

  void stopHealthMonitor() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  Future<void> checkAllHealth() async {
    for (final provider in _providers) {
      if (provider.enabled) {
        await checkHealth(provider);
      }
    }
    notifyListeners();
  }

  Future<bool> checkHealth(McpProvider provider) async {
    try {
      final response = await _sendRequest(
        provider.endpointUrl,
        'initialize',
        {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'zephaniah-flutter', 'version': '1.0.0'},
        },
      );

      if (response != null && response['serverInfo'] != null) {
        provider.isConnected = true;
        provider.serverName = response['serverInfo']['name'] as String?;
        provider.serverVersion = response['serverInfo']['version'] as String?;
        await _loadTools(provider);
        return true;
      }
    } catch (e) {
      _log.warning('McpService', 'Health check failed for ${provider.name}: $e');
    }

    provider.isConnected = false;
    provider.tools = [];
    return false;
  }

  Future<void> _loadTools(McpProvider provider) async {
    try {
      final response = await _sendRequest(
        provider.endpointUrl,
        'tools/list',
        {},
      );

      if (response != null && response['tools'] is List) {
        provider.tools = (response['tools'] as List)
            .map((t) => McpTool.fromJson(t as Map<String, dynamic>))
            .toList();
        _log.info('McpService',
            'Loaded ${provider.tools.length} tools from ${provider.name}');
      }
    } catch (e) {
      _log.error('McpService', 'Failed to load tools for ${provider.name}: $e');
    }
  }

  Future<Map<String, dynamic>?> _sendRequest(
    String endpoint,
    String method,
    Map<String, dynamic> params,
  ) async {
    final requestId = ++_requestId;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
      'params': params,
    });

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['error'] != null) {
          _log.error('McpService', 'MCP error: ${json['error']}');
          return null;
        }
        return json['result'] as Map<String, dynamic>?;
      }
    } catch (e) {
      _log.debug('McpService', 'Request failed: $e');
    }
    return null;
  }

  Future<dynamic> callTool(
    McpProvider provider,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    if (!provider.isConnected) {
      throw Exception('Provider ${provider.name} is not connected');
    }

    _log.info('McpService', 'Calling tool $toolName on ${provider.name}');

    final response = await _sendRequest(
      provider.endpointUrl,
      'tools/call',
      {
        'name': toolName,
        'arguments': arguments,
      },
    );

    if (response != null && response['content'] is List) {
      final content = response['content'] as List;
      if (content.isNotEmpty) {
        final first = content.first as Map<String, dynamic>;
        if (first['type'] == 'text') {
          return first['text'];
        }
        return first;
      }
    }

    return response;
  }

  Future<McpProvider> addProvider({
    required String name,
    required String endpointUrl,
    Map<String, dynamic>? config,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final provider = McpProvider(
      id: id,
      name: name,
      endpointUrl: endpointUrl,
      config: config,
      addedAt: DateTime.now(),
    );

    await _db.insertMcpProvider(provider.toJson());
    _providers.add(provider);

    // Check health immediately
    await checkHealth(provider);

    _log.info('McpService', 'Added MCP provider: $name');
    notifyListeners();
    return provider;
  }

  Future<void> removeProvider(String id) async {
    await _db.deleteMcpProvider(id);
    _providers.removeWhere((p) => p.id == id);
    _log.info('McpService', 'Removed MCP provider: $id');
    notifyListeners();
  }

  Future<void> toggleProvider(String id, bool enabled) async {
    final provider = _providers.firstWhere((p) => p.id == id);
    final updated = McpProvider(
      id: provider.id,
      name: provider.name,
      endpointUrl: provider.endpointUrl,
      enabled: enabled,
      config: provider.config,
      addedAt: provider.addedAt,
    );
    await _db.updateMcpProvider(updated.toJson());

    final index = _providers.indexWhere((p) => p.id == id);
    _providers[index] = updated;

    if (enabled) {
      await checkHealth(updated);
    } else {
      updated.isConnected = false;
    }

    notifyListeners();
  }

  Future<bool> testConnection(String endpointUrl) async {
    try {
      final response = await _sendRequest(
        endpointUrl,
        'initialize',
        {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'zephaniah-flutter', 'version': '1.0.0'},
        },
      );
      return response != null && response['serverInfo'] != null;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    stopHealthMonitor();
    super.dispose();
  }
}
