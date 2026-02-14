import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../services/services.dart';

/// DOJ Epstein Dataset Archives
/// Download via ZIP, Torrent, or copy magnet links
class DojArchivesPage extends StatefulWidget {
  const DojArchivesPage({super.key});

  @override
  State<DojArchivesPage> createState() => _DojArchivesPageState();
}

class _DojArchivesPageState extends State<DojArchivesPage> {
  final LogService _log = LogService();
  final SettingsService _settings = SettingsService();
  final Aria2Service _aria2 = Aria2Service();
  final ArchiveDownloadService _archiveDownloads = ArchiveDownloadService();

  @override
  void initState() {
    super.initState();
    _aria2.addListener(_onServiceChanged);
    _archiveDownloads.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _aria2.removeListener(_onServiceChanged);
    _archiveDownloads.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  // Epstein Dataset definitions - downloads from Archive.org
  static const String _archiveOrgBase = 'https://archive.org/download/Epstein-Data-Sets-So-Far';

  static final List<_DojDataset> _datasets = [
    _DojDataset(
      number: 1,
      name: 'DataSet 1',
      zipUrl: '$_archiveOrgBase/DataSet%201.zip',
      magnetUri: null,
      sizeBytes: 2652651520,
      description: 'FBI Vault documents - Part 1',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 2,
      name: 'DataSet 2',
      zipUrl: '$_archiveOrgBase/DataSet%202.zip',
      magnetUri: null,
      sizeBytes: 661431549,
      description: 'FBI Vault documents - Part 2',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 3,
      name: 'DataSet 3',
      zipUrl: '$_archiveOrgBase/DataSet%203.zip',
      magnetUri: null,
      sizeBytes: 628539392,
      description: 'FBI Vault documents - Part 3',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 4,
      name: 'DataSet 4',
      zipUrl: '$_archiveOrgBase/DataSet%204.zip',
      magnetUri: null,
      sizeBytes: 375809638,
      description: 'FBI Vault documents - Part 4',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 5,
      name: 'DataSet 5',
      zipUrl: '$_archiveOrgBase/DataSet%205.zip',
      magnetUri: null,
      sizeBytes: 64486400,
      description: 'FBI Vault documents - Part 5',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 6,
      name: 'DataSet 6',
      zipUrl: '$_archiveOrgBase/DataSet%206.zip',
      magnetUri: null,
      sizeBytes: 55574528,
      description: 'FBI Vault documents - Part 6',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 7,
      name: 'DataSet 7',
      zipUrl: '$_archiveOrgBase/DataSet%207.zip',
      magnetUri: null,
      sizeBytes: 102957056,
      description: 'FBI Vault documents - Part 7',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 8,
      name: 'DataSet 8',
      zipUrl: '$_archiveOrgBase/DataSet%208.zip',
      magnetUri: null,
      sizeBytes: 11455324160,
      description: 'FBI Vault documents - Part 8 (Large)',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 9,
      name: 'DataSet 9',
      zipUrl: '$_archiveOrgBase/DataSet%209.zip',
      magnetUri: 'magnet:?xt=urn:btih:7ac8f771678d19c75a26ea6c14e7d4c003fbf9b6&dn=DataSet9',
      sizeBytes: 103353753600,
      description: 'FBI Vault documents - Part 9',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 10,
      name: 'DataSet 10',
      zipUrl: '$_archiveOrgBase/DataSet%2010.zip',
      magnetUri: 'magnet:?xt=urn:btih:d509cc4ca1a415a9ba3b6cb920f67c44aed7fe1f&dn=DataSet10',
      sizeBytes: 88046829568,
      description: 'FBI Vault documents - Part 10',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 11,
      name: 'DataSet 11',
      zipUrl: '$_archiveOrgBase/DataSet%2011.zip',
      magnetUri: 'magnet:?xt=urn:btih:59975667f8bdd5baf9945b0e2db8a57d52d32957&dn=DataSet11',
      sizeBytes: 29527900160,
      description: 'FBI Vault documents - Part 11',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 12,
      name: 'DataSet 12',
      zipUrl: '$_archiveOrgBase/DataSet%2012.zip',
      magnetUri: null,
      sizeBytes: 119633510,
      description: 'FBI Vault documents - Part 12',
      zipAvailable: true,
    ),
    _DojDataset(
      number: 13,
      name: 'Structured Dataset',
      zipUrl: null,
      magnetUri: 'magnet:?xt=urn:btih:f5cbe5026b1f86617c520d0a9cd610d6254cbe85&dn=StructuredDataset',
      sizeBytes: 5368709120,
      description: 'Community structured dataset with organized files',
      zipAvailable: false,
    ),
  ];

  // Google Drive folder for additional archives
  static const String googleDriveUrl = 'https://drive.google.com/drive/folders/18tIY9QEGUZe0q_AFAxoPnnVBCWbqHm2p';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  Color _getSizeColor(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 50) return Colors.red;
    if (gb >= 10) return Colors.orange;
    if (gb >= 1) return Colors.amber.shade700;
    return Colors.green;
  }

  Future<void> _startZipDownload(_DojDataset dataset) async {
    if (dataset.zipUrl == null) return;

    // Show confirmation for large files (> 1GB)
    if (dataset.sizeBytes > 1024 * 1024 * 1024) {
      final confirmed = await _showLargeFileWarning(dataset);
      if (confirmed != true) return;
    }

    final downloadDir = _settings.settings.downloadLocation;
    final archivesDir = path.join(downloadDir, 'DOJ_Archives');
    final filename = '${dataset.name.replaceAll(' ', '_')}.zip';
    final filePath = path.join(archivesDir, filename);

    // Check if file already exists
    if (File(filePath).existsSync()) {
      if (!mounted) return;
      final overwrite = await _showOverwriteDialog(filename);
      if (overwrite != true) return;
      await File(filePath).delete();
    }

    // Use the persistent service for downloads
    await _archiveDownloads.startDownload(
      datasetName: dataset.name,
      url: dataset.zipUrl!,
      expectedSize: dataset.sizeBytes,
    );
  }

  Future<void> _startTorrentDownload(_DojDataset dataset) async {
    if (dataset.magnetUri == null) return;

    // Show confirmation for large files
    if (dataset.sizeBytes > 1024 * 1024 * 1024) {
      final confirmed = await _showLargeFileWarning(dataset);
      if (confirmed != true) return;
    }

    final gid = await _aria2.addMagnet(dataset.magnetUri!, name: dataset.name);
    if (gid != null) {
      _log.info('Archives', 'Started torrent: ${dataset.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Started torrent download: ${dataset.name}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to start torrent. Is aria2c installed?'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Install',
              onPressed: _showAria2InstallDialog,
            ),
          ),
        );
      }
    }
  }

  void _copyMagnetLink(_DojDataset dataset) {
    if (dataset.magnetUri == null) return;
    Clipboard.setData(ClipboardData(text: dataset.magnetUri!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Magnet link copied for ${dataset.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool?> _showLargeFileWarning(_DojDataset dataset) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Large File Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dataset.name} is ${_formatBytes(dataset.sizeBytes)}.'),
            const SizedBox(height: 8),
            const Text('This download may take a long time.'),
            const SizedBox(height: 16),
            const Text(
              'Ensure you have sufficient disk space.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showOverwriteDialog(String filename) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('File Exists'),
        content: Text('$filename already exists. Overwrite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
  }

  void _showAria2InstallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Install aria2c'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('aria2c is required for torrent downloads.'),
            const SizedBox(height: 16),
            const Text('Install with:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      'brew install aria2',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'brew install aria2'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(String folderPath) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      _log.error('Archives', 'Failed to open folder: $e');
    }
  }

  int get _totalSize => _datasets.fold(0, (sum, d) => sum + d.sizeBytes);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(theme, colorScheme),
          // Dataset list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _datasets.length + 1, // +1 for Google Drive section
              itemBuilder: (context, index) {
                if (index < _datasets.length) {
                  return _buildDatasetCard(_datasets[index], theme, colorScheme);
                } else {
                  return _buildGoogleDriveCard(theme, colorScheme);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleDriveCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade50,
              Colors.orange.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_shared,
                      color: Colors.amber.shade800,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Google Drive Archive',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'COMMUNITY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Community-maintained backup on Google Drive with organized files',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Access the community archive folder containing Epstein Files datasets. Files are organized and regularly updated by the community.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _openUrl(googleDriveUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in Browser'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: googleDriveUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Drive link copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.archive_rounded,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Epstein Files Archive',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download from Internet Archive & Google Drive',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Total size badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storage, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${_formatBytes(_totalSize)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info cards - row 1 (download sources)
          Row(
            children: [
              Expanded(
                child: _buildClickableInfoCard(
                  icon: Icons.archive,
                  title: 'Internet Archive',
                  subtitle: 'Primary source (All datasets)',
                  color: Colors.blue,
                  onTap: () => _openUrl('https://archive.org/download/Epstein-Data-Sets-So-Far'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClickableInfoCard(
                  icon: Icons.folder_shared,
                  title: 'Google Drive',
                  subtitle: 'Community backup folder',
                  color: Colors.amber.shade700,
                  onTap: () => _openUrl(googleDriveUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.cloud_download,
                  title: 'Torrent Available',
                  subtitle: 'Datasets 9, 10, 11, 13',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info cards - row 2 (resources)
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.link,
                  title: 'Magnet Links',
                  subtitle: 'Copy for external client',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClickableInfoCard(
                  icon: Icons.forum,
                  title: 'Reddit Community',
                  subtitle: 'r/Epstein discussion',
                  color: Colors.deepOrange,
                  onTap: () => _openUrl('https://www.reddit.com/r/Epstein/'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClickableInfoCard(
                  icon: Icons.code,
                  title: 'GitHub Index',
                  subtitle: 'yung-megafone/Epstein-Files',
                  color: Colors.grey.shade700,
                  onTap: () => _openUrl('https://github.com/yung-megafone/Epstein-Files'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Active downloads indicator
          if (_archiveDownloads.hasActiveDownloads)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_archiveDownloads.activeCount} download(s) in progress',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ],
              ),
            )
          else if (_aria2.isRunning)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'aria2c daemon running - Torrent downloads active',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _aria2.stopDaemon,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Torrent downloads require aria2c. Click a Torrent button to start the daemon.',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: color.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      _log.error('Archives', 'Failed to open URL: $e');
    }
  }

  Widget _buildDatasetCard(_DojDataset dataset, ThemeData theme, ColorScheme colorScheme) {
    final zipProgress = _archiveDownloads.getProgress(dataset.name);
    final torrentStatus = _aria2.torrents.values
        .where((t) => t.name.contains('DataSet${dataset.number}') || t.name.contains(dataset.name))
        .firstOrNull;
    final sizeColor = _getSizeColor(dataset.sizeBytes);
    final isLarge = dataset.sizeBytes > 10 * 1024 * 1024 * 1024;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Dataset icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sizeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${dataset.number}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: sizeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Dataset info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dataset.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isLarge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LARGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                          if (!dataset.zipAvailable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TORRENT ONLY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dataset.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Size badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sizeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sizeColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _formatBytes(dataset.sizeBytes),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: sizeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress or buttons
            _buildDownloadControls(dataset, zipProgress, torrentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadControls(
    _DojDataset dataset,
    ArchiveDownloadProgress? zipProgress,
    TorrentStatus? torrentStatus,
  ) {
    // Show ZIP progress if downloading
    if (zipProgress != null && zipProgress.status == ArchiveDownloadStatus.downloading) {
      return _buildZipProgress(dataset, zipProgress);
    }

    // Show extraction progress
    if (zipProgress != null && zipProgress.status == ArchiveDownloadStatus.extracting) {
      return _buildExtractionProgress(dataset, zipProgress);
    }

    // Show torrent progress if active
    if (torrentStatus != null && (torrentStatus.isActive || torrentStatus.isPaused)) {
      return _buildTorrentProgress(dataset, torrentStatus);
    }

    // Show completion status
    final completedProgress = zipProgress;
    if (completedProgress != null && completedProgress.status == ArchiveDownloadStatus.completed) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Extracted & Ready'),
                Text(
                  '${completedProgress.extractedFiles} files in Library',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _openFolder(completedProgress.extractedPath ?? _archiveDownloads.archivesDir),
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Folder'),
          ),
          TextButton(
            onPressed: () => _archiveDownloads.clearDownload(dataset.name),
            child: const Text('Clear'),
          ),
        ],
      );
    }

    if (torrentStatus?.isComplete == true) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('Torrent Complete'),
        ],
      );
    }

    // Show error and retry
    final failedProgress = zipProgress;
    if (failedProgress != null && failedProgress.status == ArchiveDownloadStatus.failed) {
      return Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              failedProgress.error ?? 'Download failed',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
          if (dataset.zipUrl != null)
            TextButton(
              onPressed: () => _archiveDownloads.retryDownload(
                datasetName: dataset.name,
                url: dataset.zipUrl!,
                expectedSize: dataset.sizeBytes,
              ),
              child: const Text('Retry'),
            ),
        ],
      );
    }

    // Show download buttons
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // ZIP button
        if (dataset.zipAvailable)
          FilledButton.icon(
            onPressed: () => _startZipDownload(dataset),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('ZIP'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        // Torrent button
        if (dataset.magnetUri != null)
          FilledButton.icon(
            onPressed: () => _startTorrentDownload(dataset),
            icon: const Icon(Icons.cloud_download, size: 18),
            label: const Text('Torrent'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
          ),
        // Magnet link button
        if (dataset.magnetUri != null)
          OutlinedButton.icon(
            onPressed: () => _copyMagnetLink(dataset),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Magnet'),
          ),
      ],
    );
  }

  Widget _buildZipProgress(_DojDataset dataset, ArchiveDownloadProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${progress.progressPercent}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${_formatBytes(progress.bytesReceived)} / ${_formatBytes(progress.totalBytes)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _archiveDownloads.cancelDownload(dataset.name),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtractionProgress(_DojDataset dataset, ArchiveDownloadProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.unarchive, size: 20, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            const Text(
              'Extracting files...',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.totalFiles > 0 ? progress.progress : null,
                backgroundColor: Colors.grey.shade300,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              progress.totalFiles > 0
                  ? '${progress.extractedFiles}/${progress.totalFiles}'
                  : 'Reading...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (progress.currentFile != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.currentFile!,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTorrentProgress(_DojDataset dataset, TorrentStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: status.progress,
                backgroundColor: Colors.grey.shade300,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(status.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.download, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              _formatSpeed(status.downloadSpeed),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Icon(Icons.people, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${status.numSeeders} seeds, ${status.numPeers} peers',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Spacer(),
            if (status.isPaused)
              TextButton(
                onPressed: () => _aria2.resume(status.gid),
                child: const Text('Resume'),
              )
            else
              TextButton(
                onPressed: () => _aria2.pause(status.gid),
                child: const Text('Pause'),
              ),
            TextButton(
              onPressed: () => _aria2.remove(status.gid),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DojDataset {
  final int number;
  final String name;
  final String? zipUrl;
  final String? magnetUri;
  final int sizeBytes;
  final String description;
  final bool zipAvailable;

  const _DojDataset({
    required this.number,
    required this.name,
    this.zipUrl,
    this.magnetUri,
    required this.sizeBytes,
    required this.description,
    required this.zipAvailable,
  });
}
