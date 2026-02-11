import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with SingleTickerProviderStateMixin {
  final DownloadService _download = DownloadService();
  final Aria2Service _aria2 = Aria2Service();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _download.addListener(_onDownloadChanged);
    _aria2.addListener(_onDownloadChanged);
  }

  @override
  void dispose() {
    _download.removeListener(_onDownloadChanged);
    _aria2.removeListener(_onDownloadChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final httpQueue = _download.queue;
    final httpCompleted = _download.completed;
    final torrents = _aria2.torrents.values.toList();

    // HTTP stats
    final httpDownloading = httpQueue.where((t) => t.status == DownloadStatus.downloading).toList();
    final httpQueued = httpQueue.where((t) => t.status == DownloadStatus.queued).toList();
    final httpFailed = httpQueue.where((t) => t.status == DownloadStatus.failed).toList();

    // Torrent stats
    final torrentActive = torrents.where((t) => t.isActive).length;
    final torrentComplete = torrents.where((t) => t.isComplete).length;

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
              // Combined stats
              _StatBadge(
                icon: Icons.downloading,
                count: httpDownloading.length + torrentActive,
                color: Colors.blue,
                label: 'Active',
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: Icons.check_circle,
                count: httpCompleted.length + torrentComplete,
                color: Colors.green,
                label: 'Done',
              ),
              if (httpFailed.isNotEmpty) ...[
                const SizedBox(width: 12),
                _StatBadge(
                  icon: Icons.error,
                  count: httpFailed.length,
                  color: Colors.red,
                  label: 'Failed',
                ),
              ],
            ],
          ),
        ),
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_download, size: 18),
                  const SizedBox(width: 8),
                  const Text('HTTP Downloads'),
                  if (httpQueue.isNotEmpty || httpCompleted.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${httpQueue.length + httpCompleted.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share, size: 18),
                  const SizedBox(width: 8),
                  const Text('Torrents'),
                  if (torrents.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${torrents.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHttpTab(httpQueue, httpCompleted, httpDownloading, httpQueued, httpFailed),
              _buildTorrentTab(torrents),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHttpTab(
    List<DownloadTask> queue,
    List<DownloadTask> completed,
    List<DownloadTask> downloading,
    List<DownloadTask> queued,
    List<DownloadTask> failed,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final paused = queue.where((t) => t.status == DownloadStatus.paused).toList();
    final allTasks = [...queue, ...completed];

    if (allTasks.isEmpty) {
      return Center(
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
              'No HTTP downloads',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Search to find and download individual documents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Actions bar
        if (completed.isNotEmpty || failed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        // Active downloads
        if (downloading.isNotEmpty) ...[
          _SectionHeader(title: 'Downloading', count: downloading.length, color: Colors.blue),
          ...downloading.map((task) => _DownloadTaskCard(
            task: task,
            onCancel: () => _download.cancel(task.id),
            onPause: () => _download.pause(task.id),
          )),
          const SizedBox(height: 16),
        ],
        // Queued
        if (queued.isNotEmpty) ...[
          _SectionHeader(title: 'Queued', count: queued.length, color: Colors.orange),
          ...queued.map((task) => _DownloadTaskCard(
            task: task,
            onCancel: () => _download.cancel(task.id),
          )),
          const SizedBox(height: 16),
        ],
        // Paused
        if (paused.isNotEmpty) ...[
          _SectionHeader(title: 'Paused', count: paused.length, color: Colors.grey),
          ...paused.map((task) => _DownloadTaskCard(
            task: task,
            onResume: () => _download.resume(task.id),
            onCancel: () => _download.cancel(task.id),
          )),
          const SizedBox(height: 16),
        ],
        // Failed
        if (failed.isNotEmpty) ...[
          _SectionHeader(title: 'Failed', count: failed.length, color: Colors.red),
          ...failed.map((task) => _DownloadTaskCard(
            task: task,
            onRetry: () => _download.retry(task.id),
            onCancel: () => _download.cancel(task.id),
          )),
          const SizedBox(height: 16),
        ],
        // Completed
        if (completed.isNotEmpty) ...[
          _SectionHeader(title: 'Completed', count: completed.length, color: Colors.green),
          ...completed.map((task) => _DownloadTaskCard(
            task: task,
            isCompleted: true,
          )),
        ],
      ],
    );
  }

  Widget _buildTorrentTab(List<TorrentStatus> torrents) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (torrents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No torrent downloads',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start torrent downloads from the Archives tab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            if (!_aria2.isRunning)
              OutlinedButton.icon(
                onPressed: () => _aria2.startDaemon(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start aria2 Daemon'),
              ),
          ],
        ),
      );
    }

    final active = torrents.where((t) => t.isActive).toList();
    final waiting = torrents.where((t) => t.status == 'waiting').toList();
    final paused = torrents.where((t) => t.isPaused).toList();
    final complete = torrents.where((t) => t.isComplete).toList();
    final errors = torrents.where((t) => t.isError).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Aria2 status
        Card(
          color: _aria2.isRunning
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _aria2.isRunning ? Icons.check_circle : Icons.warning,
                  color: _aria2.isRunning ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _aria2.isRunning ? 'aria2 daemon running' : 'aria2 daemon stopped',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_aria2.isRunning)
                  TextButton.icon(
                    onPressed: () => _aria2.stopDaemon(),
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _aria2.startDaemon(),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Active
        if (active.isNotEmpty) ...[
          _SectionHeader(title: 'Downloading', count: active.length, color: Colors.blue),
          ...active.map((t) => _TorrentCard(
            torrent: t,
            onPause: () => _aria2.pause(t.gid),
            onRemove: () => _aria2.remove(t.gid),
          )),
          const SizedBox(height: 16),
        ],
        // Waiting
        if (waiting.isNotEmpty) ...[
          _SectionHeader(title: 'Waiting', count: waiting.length, color: Colors.orange),
          ...waiting.map((t) => _TorrentCard(
            torrent: t,
            onRemove: () => _aria2.remove(t.gid),
          )),
          const SizedBox(height: 16),
        ],
        // Paused
        if (paused.isNotEmpty) ...[
          _SectionHeader(title: 'Paused', count: paused.length, color: Colors.grey),
          ...paused.map((t) => _TorrentCard(
            torrent: t,
            onResume: () => _aria2.resume(t.gid),
            onRemove: () => _aria2.remove(t.gid),
          )),
          const SizedBox(height: 16),
        ],
        // Errors
        if (errors.isNotEmpty) ...[
          _SectionHeader(title: 'Errors', count: errors.length, color: Colors.red),
          ...errors.map((t) => _TorrentCard(
            torrent: t,
            onRemove: () => _aria2.remove(t.gid),
          )),
          const SizedBox(height: 16),
        ],
        // Complete
        if (complete.isNotEmpty) ...[
          _SectionHeader(title: 'Complete', count: complete.length, color: Colors.green),
          ...complete.map((t) => _TorrentCard(
            torrent: t,
            onRemove: () => _aria2.remove(t.gid),
          )),
        ],
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

class _TorrentCard extends StatelessWidget {
  final TorrentStatus torrent;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRemove;

  const _TorrentCard({
    required this.torrent,
    this.onPause,
    this.onResume,
    this.onRemove,
  });

  Color _getStatusColor() {
    if (torrent.isComplete) return Colors.green;
    if (torrent.isActive) return Colors.blue;
    if (torrent.isPaused) return Colors.grey;
    if (torrent.isError) return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (torrent.isComplete) return Icons.check_circle;
    if (torrent.isActive) return Icons.downloading;
    if (torrent.isPaused) return Icons.pause_circle;
    if (torrent.isError) return Icons.error;
    return Icons.hourglass_empty;
  }

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor();

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
                        torrent.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Torrent',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            torrent.statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Speed and peers
                if (torrent.isActive) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            _formatSpeed(torrent.downloadSpeed),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${torrent.numSeeders} seeds · ${torrent.numPeers} peers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // Size
                if (torrent.totalBytes > 0)
                  Text(
                    _formatSize(torrent.totalBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
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
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove',
                    iconSize: 20,
                    color: Colors.red,
                  ),
              ],
            ),
            // Progress bar
            if (torrent.isActive || (torrent.totalBytes > 0 && !torrent.isComplete)) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: torrent.progress,
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(torrent.progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${_formatSize(torrent.completedBytes)} / ${_formatSize(torrent.totalBytes)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
