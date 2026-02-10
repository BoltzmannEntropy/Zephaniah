import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final DownloadService _download = DownloadService();

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

    final queue = _download.queue;
    final completed = _download.completed;
    final allTasks = [...queue, ...completed];

    // Group by status
    final downloading = queue.where((t) => t.status == DownloadStatus.downloading).toList();
    final queued = queue.where((t) => t.status == DownloadStatus.queued).toList();
    final paused = queue.where((t) => t.status == DownloadStatus.paused).toList();
    final failed = queue.where((t) => t.status == DownloadStatus.failed).toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.download_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Download Queue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Stats
              _StatBadge(
                icon: Icons.downloading,
                count: downloading.length,
                color: Colors.blue,
                label: 'Active',
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: Icons.hourglass_empty,
                count: queued.length,
                color: Colors.orange,
                label: 'Queued',
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: Icons.check_circle,
                count: completed.length,
                color: Colors.green,
                label: 'Done',
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(width: 12),
                _StatBadge(
                  icon: Icons.error,
                  count: failed.length,
                  color: Colors.red,
                  label: 'Failed',
                ),
              ],
              const SizedBox(width: 24),
              // Actions
              if (completed.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _download.clearCompleted(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Done'),
                ),
              if (failed.isNotEmpty)
                TextButton.icon(
                  onPressed: _retryAllFailed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Failed'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: allTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No downloads',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for documents and download them',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Active downloads
                    if (downloading.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Downloading',
                        count: downloading.length,
                        color: Colors.blue,
                      ),
                      ...downloading.map((task) => _DownloadTaskCard(
                            task: task,
                            onCancel: () => _download.cancel(task.id),
                            onPause: () => _download.pause(task.id),
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Queued
                    if (queued.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Queued',
                        count: queued.length,
                        color: Colors.orange,
                      ),
                      ...queued.map((task) => _DownloadTaskCard(
                            task: task,
                            onCancel: () => _download.cancel(task.id),
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Paused
                    if (paused.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Paused',
                        count: paused.length,
                        color: Colors.grey,
                      ),
                      ...paused.map((task) => _DownloadTaskCard(
                            task: task,
                            onResume: () => _download.resume(task.id),
                            onCancel: () => _download.cancel(task.id),
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Failed
                    if (failed.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Failed',
                        count: failed.length,
                        color: Colors.red,
                      ),
                      ...failed.map((task) => _DownloadTaskCard(
                            task: task,
                            onRetry: () => _download.retry(task.id),
                            onCancel: () => _download.cancel(task.id),
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Completed
                    if (completed.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Completed',
                        count: completed.length,
                        color: Colors.green,
                      ),
                      ...completed.map((task) => _DownloadTaskCard(
                            task: task,
                            isCompleted: true,
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _retryAllFailed() {
    final failed = _download.queue.where((t) => t.status == DownloadStatus.failed).toList();
    for (final task in failed) {
      _download.retry(task.id);
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;
  final bool isCompleted;

  const _DownloadTaskCard({
    required this.task,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.onRetry,
    this.isCompleted = false,
  });

  Color _getStatusColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.queued:
        return Colors.orange;
      case DownloadStatus.paused:
        return Colors.grey;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Icons.downloading;
      case DownloadStatus.queued:
        return Icons.hourglass_empty;
      case DownloadStatus.paused:
        return Icons.pause_circle;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor();
    final totalBytes = task.totalBytes ?? 0;
    final progress = totalBytes > 0 ? task.bytesReceived / totalBytes : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.source.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.source.domain,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress/Size
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.completed)
                  Text(
                    task.progressFormatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                const SizedBox(width: 8),
                // Actions
                if (onPause != null)
                  IconButton(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    tooltip: 'Pause',
                    iconSize: 20,
                  ),
                if (onResume != null)
                  IconButton(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Resume',
                    iconSize: 20,
                  ),
                if (onRetry != null)
                  IconButton(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Retry',
                    iconSize: 20,
                    color: Colors.orange,
                  ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    iconSize: 20,
                    color: Colors.red,
                  ),
              ],
            ),
            // Progress bar for downloading
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalBytes > 0 ? progress : null,
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalBytes > 0 ? '${(progress * 100).toInt()}%' : 'Downloading...',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (task.retryCount > 0)
                    Text(
                      'Retry ${task.retryCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ],
            // Error message for failed
            if (task.status == DownloadStatus.failed && task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
