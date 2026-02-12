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
import 'pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize services
  await SettingsService().initialize();
  await LogService().initialize();
  await DatabaseService().initialize();
  SearchService().initialize();

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
      themeMode: ThemeMode.system,
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

  // New navigation order: Archives, Library, Search, Queue, Settings, About
  final List<Widget> _pages = [
    const DojArchivesPage(),   // 0: Archives - download DOJ datasets
    const LibraryPage(),       // 1: Library - gallery view of downloaded files
    const SearchPage(),        // 2: Search - secondary feature for new documents
    const QueuePage(),         // 3: Queue - download progress
    const SettingsPage(),      // 4: Settings
    const AboutPage(),         // 5: About
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
