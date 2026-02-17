import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'services/services.dart';
import 'widgets/sidebar.dart';
import 'widgets/download_queue_panel.dart';
import 'widgets/logs_panel.dart';
import 'pages/doj_archives_page.dart';
import 'pages/library_page.dart';
import 'pages/search_page.dart';
import 'pages/queue_page.dart';
import 'pages/settings_page.dart';
import 'pages/mcp_page.dart';
import 'pages/pro_page.dart';
import 'pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final message = details.exceptionAsString();
    try {
      LogService().error('Flutter', message);
    } catch (_) {
      debugPrint('Flutter error: $message');
    }
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    try {
      LogService().error('Platform', error.toString());
    } catch (_) {
      debugPrint('Platform error: $error');
    }
    debugPrintStack(stackTrace: stack);
    return true;
  };

  final bootstrap = await _bootstrapServices();

  runZonedGuarded(
    () {
      if (bootstrap.fatalError != null) {
        runApp(StartupErrorApp(message: bootstrap.fatalError!));
      } else {
        runApp(ZephaniahApp(warnings: bootstrap.warnings));
      }
    },
    (Object error, StackTrace stack) {
      try {
        LogService().error('Zone', error.toString());
      } catch (_) {
        debugPrint('Zoned error: $error');
      }
      debugPrintStack(stackTrace: stack);
    },
  );
}

class BootstrapResult {
  final String? fatalError;
  final List<String> warnings;

  const BootstrapResult({this.fatalError, this.warnings = const []});
}

Future<BootstrapResult> _bootstrapServices() async {
  final warnings = <String>[];

  Future<void> guardedInit(
    String name,
    Future<void> Function() init, {
    bool fatal = false,
  }) async {
    try {
      await init();
    } catch (e, stack) {
      final msg = '$name initialization failed: $e';
      debugPrint(msg);
      debugPrintStack(stackTrace: stack);
      if (fatal) {
        throw Exception(msg);
      }
      warnings.add(msg);
      try {
        LogService().warning('Bootstrap', msg);
      } catch (_) {}
    }
  }

  try {
    await guardedInit(
      'MediaKit',
      () async => MediaKit.ensureInitialized(),
      fatal: true,
    );
    await guardedInit(
      'SettingsService',
      () => SettingsService().initialize(),
      fatal: true,
    );
    await guardedInit('LogService', () => LogService().initialize());
    await guardedInit('DatabaseService', () => DatabaseService().initialize());
    await guardedInit(
      'SearchService',
      () async => SearchService().initialize(),
    );
  } catch (e) {
    return BootstrapResult(fatalError: e.toString(), warnings: warnings);
  }

  return BootstrapResult(warnings: warnings);
}

class ZephaniahApp extends StatelessWidget {
  final List<String> warnings;

  const ZephaniahApp({super.key, this.warnings = const []});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zephaniah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a2e),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a2e),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: MainShell(startupWarnings: warnings),
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'A UI error occurred. Restart Zephaniah to recover.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final List<String> startupWarnings;

  const MainShell({super.key, this.startupWarnings = const []});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedPageIndex = 0;
  final SettingsService _settings = SettingsService();
  final DownloadService _download = DownloadService();

  // New navigation order: Archives, Library, Search, Queue, Settings, MCP, Pro, About
  final List<Widget> _pages = [
    const DojArchivesPage(), // 0: Archives - download DOJ datasets
    const LibraryPage(), // 1: Library - gallery view of downloaded files
    const SearchPage(), // 2: Search - secondary feature for new documents
    const QueuePage(), // 3: Queue - download progress
    const SettingsPage(), // 4: Settings
    const McpPage(), // 5: MCP - Claude integration
    const ProPage(), // 6: Pro / licensing
    const AboutPage(), // 7: About
  ];

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _download.addListener(_onDownloadChanged);
    if (widget.startupWarnings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final warningText = widget.startupWarnings.join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Startup warnings:\n$warningText'),
            duration: const Duration(seconds: 8),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _download.removeListener(_onDownloadChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  void _navigateTo(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings.settings;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedPageIndex,
            onNavigate: _navigateTo,
            downloadCount: _download.activeCount + _download.queuedCount,
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Page content
                Expanded(child: _pages[_selectedPageIndex]),
                // Download queue panel
                if (settings.showDownloadQueue &&
                    (_download.hasActiveDownloads ||
                        _download.completed.isNotEmpty))
                  DownloadQueuePanel(
                    onItemTap: (task) {
                      // Navigate to Artifacts page (index 1) when item is tapped
                      _navigateTo(1);
                      // TODO: Could pass artifact ID to select specific item
                    },
                  ),
                // Logs panel
                if (settings.showLogsPanel) const LogsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Zephaniah failed to start',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Navigation helper
class AppNavigation extends InheritedWidget {
  final void Function(int pageIndex) navigateTo;

  const AppNavigation({
    super.key,
    required this.navigateTo,
    required super.child,
  });

  static AppNavigation? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigation>();
  }

  @override
  bool updateShouldNotify(AppNavigation oldWidget) {
    return navigateTo != oldWidget.navigateTo;
  }
}
