import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
  });

  String get formatted {
    final time = DateFormat('HH:mm:ss').format(timestamp);
    final levelStr = level.name.toUpperCase().padRight(7);
    return '[$time] $levelStr [$source] $message';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'source': source,
        'message': message,
      };
}

class LogService extends ChangeNotifier {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const int _maxEntries = 500;
  final List<LogEntry> _entries = [];
  File? _logFile;

  List<LogEntry> get entries => List.unmodifiable(_entries);
  List<LogEntry> get recentEntries =>
      _entries.length > 50 ? _entries.sublist(_entries.length - 50) : _entries;

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/Zephaniah/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/zephaniah_$today.log');
      info('LogService', 'Log service initialized');
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  void _log(LogLevel level, String source, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: message,
    );

    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }

    // Write to file asynchronously
    _writeToFile(entry);

    // Debug print
    if (kDebugMode) {
      debugPrint(entry.formatted);
    }

    notifyListeners();
  }

  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;
    try {
      await _logFile!.writeAsString(
        '${entry.formatted}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Failed to write log: $e');
    }
  }

  void debug(String source, String message) =>
      _log(LogLevel.debug, source, message);

  void info(String source, String message) =>
      _log(LogLevel.info, source, message);

  void warning(String source, String message) =>
      _log(LogLevel.warning, source, message);

  void error(String source, String message) =>
      _log(LogLevel.error, source, message);

  List<LogEntry> filterByLevel(LogLevel level) =>
      _entries.where((e) => e.level == level).toList();

  List<LogEntry> filterBySource(String source) =>
      _entries.where((e) => e.source == source).toList();

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  Future<String> export() async {
    return _entries.map((e) => e.formatted).join('\n');
  }

  Future<File?> exportToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final file = File('${dir.path}/Zephaniah/logs/export_$timestamp.log');
      await file.writeAsString(await export());
      return file;
    } catch (e) {
      error('LogService', 'Failed to export logs: $e');
      return null;
    }
  }
}
