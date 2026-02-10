import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'widgets/sidebar.dart';
import 'widgets/download_queue_panel.dart';
import 'widgets/logs_panel.dart';
import 'pages/search_page.dart';
import 'pages/artifacts_page.dart';
import 'pages/snapshots_page.dart';
import 'pages/mcp_page.dart';
import 'pages/queue_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize services
  await SettingsService().initialize();
  await LogService().initialize();
  await DatabaseService().initialize();
  SearchService().initialize();
  McpService().initialize();

  runApp(const ZephaniahApp());
}

class ZephaniahApp extends StatelessWidget {
  const ZephaniahApp({super.key});

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
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
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
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedPageIndex = 0;
  final SettingsService _settings = SettingsService();
  final DownloadService _download = DownloadService();

  final List<Widget> _pages = [
    const SearchPage(),
    const ArtifactsPage(),
    const SnapshotsPage(),
    const McpPage(),
    const QueuePage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _download.addListener(_onDownloadChanged);
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
                Expanded(
                  child: _pages[_selectedPageIndex],
                ),
                // Download queue panel
                if (settings.showDownloadQueue &&
                    (_download.hasActiveDownloads || _download.completed.isNotEmpty))
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
