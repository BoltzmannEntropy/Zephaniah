import 'dart:io';
import 'package:flutter/material.dart';
import '../services/services.dart';
import 'library_viewer_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LibraryService _library = LibraryService();
  final ThumbnailService _thumbnails = ThumbnailService();
  final TextEditingController _searchController = TextEditingController();

  bool _isGeneratingThumbnails = false;
  int _thumbnailProgress = 0;
  int _thumbnailTotal = 0;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _library.addListener(_onLibraryChanged);
    _loadLibrary();
  }

  @override
  void dispose() {
    _library.removeListener(_onLibraryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLibrary() async {
    await _library.scanLibrary();
    _generateThumbnails();
  }

  Future<void> _generateThumbnails() async {
    final files = _library.files;
    if (files.isEmpty) return;

    setState(() {
      _isGeneratingThumbnails = true;
      _thumbnailTotal = files.length;
      _thumbnailProgress = 0;
    });

    await _thumbnails.generateThumbnailsBatch(
      files,
      onProgress: (completed, total) {
        if (mounted) {
          setState(() {
            _thumbnailProgress = completed;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isGeneratingThumbnails = false;
      });
    }
  }

  void _onSearch(String query) {
    _library.setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _library.getStats();
    final files = _library.files;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Library',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      '${stats.totalFiles} files · ${stats.sizeFormatted}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // View toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.grid_view),
                        tooltip: 'Grid View',
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_list),
                        tooltip: 'List View',
                      ),
                    ],
                    selected: {_isGridView},
                    onSelectionChanged: (selected) {
                      setState(() => _isGridView = selected.first);
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _library.isScanning ? null : _loadLibrary,
                    icon: _library.isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: 'Rescan Library',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search and filters
              Row(
                children: [
                  // Search box
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search files...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _onSearch,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Dataset filter
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: _library.currentDataset,
                      decoration: InputDecoration(
                        labelText: 'Dataset',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Datasets'),
                        ),
                        ..._library.datasets.values.map((d) => DropdownMenuItem(
                              value: d.name,
                              child: Text(
                                '${d.name} (${d.fileCount})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (value) => _library.setDatasetFilter(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Type filter
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: _library.currentFileType,
                      decoration: InputDecoration(
                        labelText: 'File Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...stats.typeCounts.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Row(
                                children: [
                                  Icon(
                                    _getTypeIcon(e.key),
                                    size: 18,
                                    color: _getTypeColor(e.key),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${e.key} (${e.value})'),
                                ],
                              ),
                            )),
                      ],
                      onChanged: (value) => _library.setTypeFilter(value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Thumbnail generation progress
        if (_isGeneratingThumbnails)
          LinearProgressIndicator(
            value: _thumbnailTotal > 0 ? _thumbnailProgress / _thumbnailTotal : null,
          ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: _library.isScanning
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Scanning library...'),
                    ],
                  ),
                )
              : files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files in library',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Download archives from the Archives tab',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? _buildGridView(files)
                      : _buildListView(files),
        ),
      ],
    );
  }

  Widget _buildGridView(List<LibraryFile> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) => _buildGridItem(files[index]),
    );
  }

  Widget _buildGridItem(LibraryFile file) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getTypeColor(file.fileType);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openViewer(file),
        onSecondaryTap: () => _showContextMenu(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                color: color.withValues(alpha: 0.1),
                child: file.thumbnailPath != null
                    ? Image.file(
                        File(file.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(file),
                      )
                    : _buildPlaceholder(file),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(file.fileType),
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          file.sizeFormatted,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(LibraryFile file) {
    final color = _getTypeColor(file.fileType);
    return Center(
      child: Icon(
        _getTypeIcon(file.fileType),
        size: 48,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildListView(List<LibraryFile> files) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final color = _getTypeColor(file.fileType);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: file.thumbnailPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(file.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _getTypeIcon(file.fileType),
                          color: color,
                        ),
                      ),
                    )
                  : Icon(
                      _getTypeIcon(file.fileType),
                      color: color,
                    ),
            ),
            title: Text(
              file.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.dataset,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  file.sizeFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, file),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: ListTile(
                    leading: Icon(Icons.open_in_new),
                    title: Text('Open'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'reveal',
                  child: ListTile(
                    leading: Icon(Icons.folder_open),
                    title: Text('Reveal in Finder'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _openViewer(file),
          ),
        );
      },
    );
  }

  void _showContextMenu(LibraryFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                _openViewer(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Reveal in Finder'),
              onTap: () {
                Navigator.pop(context);
                _library.revealInFinder(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(LibraryFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryViewerPage(file: file),
      ),
    );
  }

  void _handleMenuAction(String action, LibraryFile file) {
    switch (action) {
      case 'open':
        _openViewer(file);
        break;
      case 'reveal':
        _library.revealInFinder(file);
        break;
      case 'delete':
        _confirmDelete(file);
        break;
    }
  }

  Future<void> _confirmDelete(LibraryFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.filename}"?'),
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

    if (confirm == true) {
      final success = await _library.deleteFile(file);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${file.filename}')),
        );
      }
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'spreadsheet':
        return Icons.table_chart;
      case 'text':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.orange;
      case 'audio':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'document':
        return Colors.blue;
      case 'spreadsheet':
        return Colors.green;
      case 'text':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
