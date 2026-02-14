import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'log_service.dart';
import 'settings_service.dart';

/// Service for managing aria2c daemon and torrent downloads
class Aria2Service extends ChangeNotifier {
  static final Aria2Service _instance = Aria2Service._internal();
  factory Aria2Service() => _instance;
  Aria2Service._internal();

  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();

  Process? _daemonProcess;
  bool _isRunning = false;
  Timer? _statusTimer;

  static const int _rpcPort = 6800;
  static const String _rpcUrl = 'http://localhost:6800/jsonrpc';

  final Map<String, TorrentStatus> _torrents = {};

  bool get isRunning => _isRunning;
  Map<String, TorrentStatus> get torrents => Map.unmodifiable(_torrents);

  /// Start aria2c daemon
  Future<bool> startDaemon() async {
    if (_isRunning) return true;

    // Check if aria2c is installed
    try {
      final result = await Process.run('which', ['aria2c']);
      if (result.exitCode != 0) {
        _log.error('Aria2', 'aria2c not found. Install with: brew install aria2');
        return false;
      }
    } catch (e) {
      _log.error('Aria2', 'Failed to check aria2c: $e');
      return false;
    }

    // Get download directory
    final downloadDir = '${_settings.settings.downloadLocation}/DOJ_Archives';
    await Directory(downloadDir).create(recursive: true);

    try {
      _daemonProcess = await Process.start(
        'aria2c',
        [
          '--enable-rpc',
          '--rpc-listen-port=$_rpcPort',
          '--rpc-listen-all=false',
          '--dir=$downloadDir',
          '--continue=true',
          '--max-concurrent-downloads=3',
          '--max-connection-per-server=4',
          '--split=4',
          '--min-split-size=1M',
          '--seed-time=0', // Don't seed after download
          '--bt-stop-timeout=300', // Stop after 5 min if no progress
          '--quiet=true',
        ],
      );

      // Drain stdout/stderr to avoid process pipe backpressure.
      unawaited(_daemonProcess!.stdout.drain<List<int>>(<int>[]));
      unawaited(_daemonProcess!.stderr.drain<List<int>>(<int>[]));

      // Wait for daemon to start
      await Future.delayed(const Duration(seconds: 2));

      // Check if running
      final isUp = await _checkDaemon();
      if (isUp) {
        _isRunning = true;
        _startStatusPolling();
        _log.info('Aria2', 'Daemon started on port $_rpcPort');
        notifyListeners();
        return true;
      } else {
        _log.error('Aria2', 'Daemon failed to start');
        return false;
      }
    } catch (e) {
      _log.error('Aria2', 'Failed to start daemon: $e');
      return false;
    }
  }

  /// Stop aria2c daemon
  Future<void> stopDaemon() async {
    _statusTimer?.cancel();
    _statusTimer = null;

    if (_daemonProcess != null) {
      _daemonProcess!.kill();
      _daemonProcess = null;
    }

    _isRunning = false;
    _torrents.clear();
    notifyListeners();
    _log.info('Aria2', 'Daemon stopped');
  }

  /// Check if daemon is running
  Future<bool> _checkDaemon() async {
    try {
      final response = await _rpcCall('aria2.getVersion', []);
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Start polling for status updates
  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_updateAllStatus());
    });
  }

  /// Add a torrent via magnet link
  Future<String?> addMagnet(String magnetUri, {String? name}) async {
    if (!_isRunning) {
      final started = await startDaemon();
      if (!started) return null;
    }

    try {
      final result = await _rpcCall('aria2.addUri', [
        [magnetUri],
        {},
      ]);

      if (result != null) {
        final gid = result as String;
        _torrents[gid] = TorrentStatus(
          gid: gid,
          name: name ?? 'Unknown',
          status: 'waiting',
          totalBytes: 0,
          completedBytes: 0,
          downloadSpeed: 0,
          uploadSpeed: 0,
          numSeeders: 0,
          numPeers: 0,
        );
        _log.info('Aria2', 'Added torrent: $name (GID: $gid)');
        notifyListeners();
        return gid;
      }
    } catch (e) {
      _log.error('Aria2', 'Failed to add magnet: $e');
    }
    return null;
  }

  /// Pause a torrent
  Future<bool> pause(String gid) async {
    try {
      await _rpcCall('aria2.pause', [gid]);
      _log.info('Aria2', 'Paused: $gid');
      return true;
    } catch (e) {
      _log.error('Aria2', 'Failed to pause: $e');
      return false;
    }
  }

  /// Resume a torrent
  Future<bool> resume(String gid) async {
    try {
      await _rpcCall('aria2.unpause', [gid]);
      _log.info('Aria2', 'Resumed: $gid');
      return true;
    } catch (e) {
      _log.error('Aria2', 'Failed to resume: $e');
      return false;
    }
  }

  /// Remove a torrent
  Future<bool> remove(String gid) async {
    try {
      await _rpcCall('aria2.remove', [gid]);
      _torrents.remove(gid);
      _log.info('Aria2', 'Removed: $gid');
      notifyListeners();
      return true;
    } catch (e) {
      _log.error('Aria2', 'Failed to remove: $e');
      return false;
    }
  }

  /// Update status for all torrents
  Future<void> _updateAllStatus() async {
    if (!_isRunning) return;

    try {
      // Get active downloads
      final activeResult = await _rpcCall('aria2.tellActive', []);
      // Get waiting downloads
      final waitingResult = await _rpcCall('aria2.tellWaiting', [0, 100]);
      // Get stopped/completed downloads
      final stoppedResult = await _rpcCall('aria2.tellStopped', [0, 100]);

      // Safely convert results to lists
      final active = activeResult is List ? activeResult : <dynamic>[];
      final waiting = waitingResult is List ? waitingResult : <dynamic>[];
      final stopped = stoppedResult is List ? stoppedResult : <dynamic>[];

      final allDownloads = [...active, ...waiting, ...stopped];

      for (final download in allDownloads) {
        if (download is! Map<String, dynamic>) continue;
        final gid = download['gid'];
        if (gid is! String) continue;

        final status = _parseStatus(download);
        _torrents[gid] = status;
      }

      notifyListeners();
    } catch (e) {
      // Log polling errors for debugging but don't crash
      _log.error('Aria2', 'Status poll failed: $e');
    }
  }

  TorrentStatus _parseStatus(Map<String, dynamic> data) {
    final files = data['files'];
    String name = 'Unknown';

    if (files is List && files.isNotEmpty) {
      final firstFile = files[0];
      if (firstFile is Map) {
        final path = firstFile['path']?.toString() ?? '';
        name = path.split('/').last;
      }
    }

    if (name.isEmpty || name == 'Unknown') {
      // Try to get name from bittorrent metadata
      final bt = data['bittorrent'];
      if (bt is Map) {
        final info = bt['info'];
        if (info is Map) {
          name = info['name']?.toString() ?? 'Unknown';
        }
      }
    }

    return TorrentStatus(
      gid: data['gid']?.toString() ?? '',
      name: name,
      status: data['status']?.toString() ?? 'unknown',
      totalBytes: int.tryParse(data['totalLength']?.toString() ?? '0') ?? 0,
      completedBytes: int.tryParse(data['completedLength']?.toString() ?? '0') ?? 0,
      downloadSpeed: int.tryParse(data['downloadSpeed']?.toString() ?? '0') ?? 0,
      uploadSpeed: int.tryParse(data['uploadSpeed']?.toString() ?? '0') ?? 0,
      numSeeders: int.tryParse(data['numSeeders']?.toString() ?? '0') ?? 0,
      numPeers: int.tryParse(data['connections']?.toString() ?? '0') ?? 0,
    );
  }

  /// Make JSON-RPC call to aria2c
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'method': method,
      'params': params,
    });

    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid aria2 RPC payload');
      }
      if (decoded['error'] != null) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          throw Exception(error['message']);
        }
        throw Exception(error.toString());
      }
      return decoded['result'];
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    stopDaemon();
    super.dispose();
  }
}

/// Status of a torrent download
class TorrentStatus {
  final String gid;
  final String name;
  final String status; // active, waiting, paused, error, complete, removed
  final int totalBytes;
  final int completedBytes;
  final int downloadSpeed;
  final int uploadSpeed;
  final int numSeeders;
  final int numPeers;

  TorrentStatus({
    required this.gid,
    required this.name,
    required this.status,
    required this.totalBytes,
    required this.completedBytes,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.numSeeders,
    required this.numPeers,
  });

  double get progress => totalBytes > 0 ? completedBytes / totalBytes : 0;
  bool get isComplete => status == 'complete' || (totalBytes > 0 && completedBytes >= totalBytes);
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isError => status == 'error';

  String get statusText {
    switch (status) {
      case 'active':
        return 'Downloading';
      case 'waiting':
        return 'Waiting';
      case 'paused':
        return 'Paused';
      case 'error':
        return 'Error';
      case 'complete':
        return 'Complete';
      case 'removed':
        return 'Removed';
      default:
        return status;
    }
  }
}
