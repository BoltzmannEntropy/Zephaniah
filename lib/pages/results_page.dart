import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class ResultsPage extends StatefulWidget {
  final SearchResultBatch results;
  final SearchQuery query;

  const ResultsPage({
    super.key,
    required this.results,
    required this.query,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final DownloadService _download = DownloadService();
  final Set<String> _selectedResults = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _download.addListener(_onDownloadChanged);
  }

  @override
  void dispose() {
    _download.removeListener(_onDownloadChanged);
    super.dispose();
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final results = widget.results.results;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results (${results.length})'),
        actions: [
          if (results.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectAll = !_selectAll;
                  if (_selectAll) {
                    _selectedResults.addAll(results.map((r) => r.id));
                  } else {
                    _selectedResults.clear();
                  }
                });
              },
              icon: Icon(_selectAll
                  ? Icons.deselect
                  : Icons.select_all),
              label: Text(_selectAll ? 'Deselect All' : 'Select All'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _selectedResults.isEmpty
                  ? null
                  : () => _downloadSelected(),
              icon: const Icon(Icons.download),
              label: Text('Download (${_selectedResults.length})'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try different search terms or filters',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Query info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Query: ${widget.results.query}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Engine: ${widget.query.engine.label}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Results list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final isSelected = _selectedResults.contains(result.id);

                      return _ResultCard(
                        result: result,
                        isSelected: isSelected,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedResults.remove(result.id);
                            } else {
                              _selectedResults.add(result.id);
                            }
                          });
                        },
                        onDownload: () => _downloadSingle(result),
                      );
                    },
                  ),
                ),
                // Download progress section
                if (_download.queue.isNotEmpty || _download.completed.isNotEmpty)
                  _buildDownloadProgress(theme),
              ],
            ),
    );
  }

  Future<void> _downloadSelected() async {
    final results = widget.results.results
        .where((r) => _selectedResults.contains(r.id))
        .toList();

    if (results.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items selected')),
        );
      }
      return;
    }

    final tasks = await _download.enqueueAll(results);
    final skipped = results.length - tasks.length;

    if (mounted) {
      String message;
      if (tasks.isEmpty && skipped > 0) {
        message = 'All $skipped files already downloaded';
      } else if (skipped > 0) {
        message = 'Added ${tasks.length} files to queue ($skipped duplicates skipped)';
      } else {
        message = 'Added ${tasks.length} files to download queue';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _downloadSingle(SearchResult result) async {
    try {
      await _download.enqueue(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${result.title}" to download queue')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Widget _buildDownloadProgress(ThemeData theme) {
    final queue = _download.queue;
    final completedList = _download.completed;
    final colorScheme = theme.colorScheme;

    final completedCount = completedList.length;
    final failed = queue.where((t) => t.status == DownloadStatus.failed).length;
    final inProgress = queue.where((t) => t.status == DownloadStatus.downloading).toList();
    final pending = queue.where((t) => t.status == DownloadStatus.queued).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.download, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Downloads',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Status badges
              _StatusBadge(
                icon: Icons.check_circle,
                count: completedCount,
                color: Colors.green,
                label: 'Done',
              ),
              const SizedBox(width: 12),
              _StatusBadge(
                icon: Icons.hourglass_empty,
                count: pending,
                color: Colors.orange,
                label: 'Pending',
              ),
              if (failed > 0) ...[
                const SizedBox(width: 12),
                _StatusBadge(
                  icon: Icons.error,
                  count: failed,
                  color: Colors.red,
                  label: 'Failed',
                ),
              ],
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _download.clearCompleted(),
                child: const Text('Clear Done'),
              ),
            ],
          ),
          // Progress bars for active downloads
          if (inProgress.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...inProgress.take(3).map((task) {
              final totalBytes = task.totalBytes ?? 0;
              final progress = totalBytes > 0
                  ? task.bytesReceived / totalBytes
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.source.filename,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: totalBytes > 0 ? progress : null,
                            backgroundColor: colorScheme.surfaceContainerLow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalBytes > 0
                              ? '${(progress * 100).toInt()}%'
                              : 'Downloading...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (inProgress.length > 3)
              Text(
                '+${inProgress.length - 3} more downloading...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String label;

  const _StatusBadge({
    required this.icon,
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDownload;

  const _ResultCard({
    required this.result,
    required this.isSelected,
    required this.onToggle,
    required this.onDownload,
  });

  Color _getFileTypeColor(FileType? type) {
    if (type == null) return Colors.grey;
    switch (type) {
      case FileType.pdf:
        return Colors.red;
      case FileType.doc:
      case FileType.docx:
        return Colors.blue;
      case FileType.xls:
      case FileType.xlsx:
        return Colors.green;
      case FileType.mp3:
      case FileType.wav:
        return Colors.purple;
      case FileType.mp4:
      case FileType.mov:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileTypeColor = _getFileTypeColor(result.fileType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
              ),
              const SizedBox(width: 8),
              // File type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fileTypeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.fileType?.label ?? 'FILE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fileTypeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.snippet != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        result.snippet!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result.domain,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (result.fileSize != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.storage,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.fileSize!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Download button
              IconButton(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                tooltip: 'Download',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
