import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'viewer_page.dart';

class ArtifactsPage extends StatefulWidget {
  const ArtifactsPage({super.key});

  @override
  State<ArtifactsPage> createState() => _ArtifactsPageState();
}

class _ArtifactsPageState extends State<ArtifactsPage> {
  final DatabaseService _db = DatabaseService();
  List<Artifact> _artifacts = [];
  List<Artifact> _allArtifacts = []; // For stats
  bool _isLoading = true;
  FileType? _filterType;
  DateTime? _filterDate;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
    _db.addListener(_loadArtifacts);
  }

  @override
  void dispose() {
    _db.removeListener(_loadArtifacts);
    super.dispose();
  }

  Future<void> _loadArtifacts() async {
    setState(() => _isLoading = true);
    try {
      // Load filtered artifacts
      final artifacts = await _db.getArtifacts(
        fileType: _filterType,
        date: _filterDate,
        limit: 200,
      );
      // Load all artifacts for stats
      final allArtifacts = await _db.getArtifacts(limit: 1000);
      setState(() {
        _artifacts = artifacts;
        _allArtifacts = allArtifacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, _FileTypeStat> _calculateStats() {
    final stats = <String, _FileTypeStat>{};

    // Count by file type
    for (final artifact in _allArtifacts) {
      final ext = artifact.filePath.split('.').last.toLowerCase();
      final type = artifact.fileType?.extension ?? ext;
      final key = type.toUpperCase();

      if (!stats.containsKey(key)) {
        stats[key] = _FileTypeStat(
          type: key,
          count: 0,
          totalSize: 0,
          color: _getTypeColor(type),
        );
      }
      stats[key] = _FileTypeStat(
        type: key,
        count: stats[key]!.count + 1,
        totalSize: stats[key]!.totalSize + (artifact.fileSize ?? 0),
        color: stats[key]!.color,
      );
    }

    return stats;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'mp3':
      case 'wav':
        return Colors.purple;
      case 'mp4':
      case 'mov':
        return Colors.orange;
      case 'ppt':
      case 'pptx':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  void _openViewer(Artifact artifact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewerPage(artifact: artifact),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _calculateStats();
    if (stats.isEmpty) return const SizedBox.shrink();

    // Sort by count descending
    final sortedStats = stats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortedStats.map((stat) {
            final isSelected = _filterType?.extension.toUpperCase() == stat.type;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _filterType = null;
                    } else {
                      _filterType = FileType.fromExtension(stat.type.toLowerCase());
                    }
                  });
                  _loadArtifacts();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: isSelected ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: stat.color, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(stat.type),
                        color: stat.color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stat.type,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: stat.color,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${stat.count} files · ${_formatSize(stat.totalSize)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: stat.color.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(_artifacts.map((a) => a.id));
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artifacts'),
        content: Text('Are you sure you want to delete $count artifact(s)? This will also delete the files from disk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final id in _selectedIds.toList()) {
      final artifact = _artifacts.firstWhere((a) => a.id == id);
      // Delete file from disk
      try {
        final file = File(artifact.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // File may not exist, continue with database deletion
      }
      await _db.deleteArtifact(id);
    }

    _clearSelection();
    _loadArtifacts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count artifact(s)')),
      );
    }
  }

  Future<void> _openInFinder() async {
    // Get unique folders for selected artifacts
    final folders = <String>{};
    for (final id in _selectedIds) {
      final artifact = _artifacts.firstWhere((a) => a.id == id);
      final file = File(artifact.filePath);
      folders.add(file.parent.path);
    }

    for (final folder in folders) {
      if (Platform.isMacOS) {
        await Process.run('open', [folder]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [folder]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folder]);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened ${folders.length} folder(s) in file manager')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group artifacts by date
    final groupedByDate = <String, List<Artifact>>{};
    for (final artifact in _artifacts) {
      final dateKey = DateFormat('yyyy-MM-dd').format(artifact.downloadedAt);
      groupedByDate.putIfAbsent(dateKey, () => []).add(artifact);
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Artifacts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_artifacts.length} files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Selection actions
              if (_isSelectionMode) ...[
                Text(
                  '${_selectedIds.length} selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.select_all),
                  label: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _openInFinder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Folder'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ] else ...[
                // Filters
                _FilterChip(
                  label: 'All Types',
                  isSelected: _filterType == null,
                  onTap: () {
                    setState(() => _filterType = null);
                    _loadArtifacts();
                  },
                ),
                _FilterChip(
                  label: 'PDF',
                  isSelected: _filterType == FileType.pdf,
                  color: Colors.red,
                  onTap: () {
                    setState(() => _filterType = FileType.pdf);
                    _loadArtifacts();
                  },
                ),
                _FilterChip(
                  label: 'Audio',
                  isSelected: _filterType == FileType.mp3,
                  color: Colors.purple,
                  onTap: () {
                    setState(() => _filterType = FileType.mp3);
                    _loadArtifacts();
                  },
                ),
                _FilterChip(
                  label: 'Video',
                  isSelected: _filterType == FileType.mp4,
                  color: Colors.orange,
                  onTap: () {
                    setState(() => _filterType = FileType.mp4);
                    _loadArtifacts();
                  },
                ),
              ],
            ],
          ),
        ),
        // File type stats cards
        if (_allArtifacts.isNotEmpty && !_isSelectionMode) _buildStatsCards(),
        const Divider(height: 1),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _artifacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No artifacts yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Download documents from search results',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedByDate.length,
                      itemBuilder: (context, index) {
                        final date = groupedByDate.keys.elementAt(index);
                        final artifacts = groupedByDate[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(date),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${artifacts.length} files)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Artifacts
                            ...artifacts.map((artifact) => _ArtifactCard(
                                  artifact: artifact,
                                  isSelected: _selectedIds.contains(artifact.id),
                                  isSelectionMode: _isSelectionMode,
                                  onTap: () => _openViewer(artifact),
                                  onLongPress: () => _toggleSelection(artifact.id),
                                  onToggleSelect: () => _toggleSelection(artifact.id),
                                )),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: effectiveColor.withValues(alpha: 0.2),
        checkmarkColor: effectiveColor,
      ),
    );
  }
}

class _FileTypeStat {
  final String type;
  final int count;
  final int totalSize;
  final Color color;

  const _FileTypeStat({
    required this.type,
    required this.count,
    required this.totalSize,
    required this.color,
  });
}

class _ArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;

  const _ArtifactCard({
    required this.artifact,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
  });

  Color _getFileTypeColor() {
    if (artifact.isPdf) return Colors.red;
    if (artifact.isAudio) return Colors.purple;
    if (artifact.isVideo) return Colors.orange;
    if (artifact.isDocument) return Colors.blue;
    return Colors.grey;
  }

  IconData _getFileTypeIcon() {
    if (artifact.isPdf) return Icons.picture_as_pdf;
    if (artifact.isAudio) return Icons.audio_file;
    if (artifact.isVideo) return Icons.video_file;
    if (artifact.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileColor = _getFileTypeColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isSelectionMode ? onToggleSelect : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox when in selection mode
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect(),
                ),
                const SizedBox(width: 8),
              ],
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(),
                  color: fileColor,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.filename,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            artifact.domain,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          artifact.fileSizeFormatted,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Open button
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
