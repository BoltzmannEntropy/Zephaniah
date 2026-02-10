import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';

class DownloadQueuePanel extends StatefulWidget {
  final void Function(DownloadTask task)? onItemTap;

  const DownloadQueuePanel({super.key, this.onItemTap});

  @override
  State<DownloadQueuePanel> createState() => _DownloadQueuePanelState();
}

class _DownloadQueuePanelState extends State<DownloadQueuePanel> {
  final DownloadService _download = DownloadService();
  bool _isExpanded = true;

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

    final activeCount = _download.activeCount;
    final queuedCount = _download.queuedCount;
    final completedCount = _download.completedCount;
    final failedCount = _download.failedCount;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Downloads',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (activeCount > 0)
                    _Badge(
                      label: '$activeCount active',
                      color: Colors.blue,
                    ),
                  if (queuedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '$queuedCount queued',
                      color: Colors.orange,
                    ),
                  ],
                  if (completedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '$completedCount done',
                      color: Colors.green,
                    ),
                  ],
                  if (failedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '$failedCount failed',
                      color: Colors.red,
                    ),
                  ],
                  const Spacer(),
                  if (_download.completed.isNotEmpty)
                    TextButton.icon(
                      onPressed: _download.clearCompleted,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                children: [
                  // Active/Queued downloads
                  ..._download.queue.map((task) => _DownloadItem(
                        task: task,
                        onTap: widget.onItemTap,
                      )),
                  // Completed downloads (show last 5)
                  ..._download.completed.reversed.take(5).map(
                        (task) => _DownloadItem(
                          task: task,
                          onTap: widget.onItemTap,
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final DownloadTask task;
  final void Function(DownloadTask task)? onTap;

  const _DownloadItem({required this.task, this.onTap});

  IconData _getFileTypeIcon(FileType? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    switch (fileType) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.doc:
      case FileType.docx:
        return Icons.description;
      case FileType.xls:
      case FileType.xlsx:
        return Icons.table_chart;
      case FileType.ppt:
      case FileType.pptx:
        return Icons.slideshow;
      case FileType.txt:
        return Icons.text_snippet;
      case FileType.mp3:
      case FileType.wav:
        return Icons.audiotrack;
      case FileType.mp4:
      case FileType.mov:
        return Icons.videocam;
    }
  }

  Color _getFileTypeColor(FileType? fileType) {
    if (fileType == null) return Colors.grey;
    switch (fileType) {
      case FileType.pdf:
        return Colors.red;
      case FileType.doc:
      case FileType.docx:
        return Colors.blue;
      case FileType.xls:
      case FileType.xlsx:
        return Colors.green;
      case FileType.ppt:
      case FileType.pptx:
        return Colors.orange;
      case FileType.txt:
        return Colors.blueGrey;
      case FileType.mp3:
      case FileType.wav:
        return Colors.purple;
      case FileType.mp4:
      case FileType.mov:
        return Colors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final download = DownloadService();

    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case DownloadStatus.queued:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case DownloadStatus.downloading:
        statusColor = Colors.blue;
        statusIcon = Icons.downloading;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.grey;
        statusIcon = Icons.pause;
        break;
      case DownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case DownloadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    final fileType = task.source.fileType;
    final fileTypeIcon = _getFileTypeIcon(fileType);
    final fileTypeColor = _getFileTypeColor(fileType);

    return InkWell(
      onTap: onTap != null ? () => onTap!(task) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: fileTypeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(fileTypeIcon, size: 16, color: fileTypeColor),
            ),
            const SizedBox(width: 8),
            // Status icon
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (fileType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: fileTypeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            fileType.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: fileTypeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          task.source.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (task.status == DownloadStatus.downloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: task.progress,
                              backgroundColor: colorScheme.outlineVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${task.progressPercent}%',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (task.errorMessage != null)
                    Text(
                      task.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.source.domain,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            // Actions
            if (task.status == DownloadStatus.downloading)
              IconButton(
                icon: const Icon(Icons.pause, size: 16),
                onPressed: () => download.pause(task.id),
                tooltip: 'Pause',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (task.status == DownloadStatus.paused)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 16),
                onPressed: () => download.resume(task.id),
                tooltip: 'Resume',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (task.canRetry)
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                onPressed: () => download.retry(task.id),
                tooltip: 'Retry',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (task.isActive)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => download.cancel(task.id),
                tooltip: 'Cancel',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            // Open in viewer icon for completed
            if (task.isComplete && onTap != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                onPressed: () => onTap!(task),
                tooltip: 'Open in Artifacts',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}
