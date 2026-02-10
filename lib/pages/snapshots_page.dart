import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';

class SnapshotsPage extends StatefulWidget {
  const SnapshotsPage({super.key});

  @override
  State<SnapshotsPage> createState() => _SnapshotsPageState();
}

class _SnapshotsPageState extends State<SnapshotsPage> {
  final SnapshotService _snapshot = SnapshotService();
  final DatabaseService _db = DatabaseService();
  List<Snapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
    _snapshot.addListener(_onSnapshotChanged);
    _db.addListener(_loadSnapshots);
  }

  @override
  void dispose() {
    _snapshot.removeListener(_onSnapshotChanged);
    _db.removeListener(_loadSnapshots);
    super.dispose();
  }

  void _onSnapshotChanged() {
    if (mounted) {
      setState(() {});
      _loadSnapshots();
    }
  }

  Future<void> _loadSnapshots() async {
    setState(() => _isLoading = true);
    try {
      final snapshots = await _snapshot.getSnapshots(limit: 100);
      setState(() {
        _snapshots = snapshots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Snapshots',
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
                  '${_snapshots.length} snapshots',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Current snapshot status
              if (_snapshot.isRunning && _snapshot.currentSnapshot != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Running: ${_snapshot.currentSnapshot!.artifactsFound} found, ${_snapshot.currentSnapshot!.newArtifacts} new',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _snapshot.cancelSnapshot,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _snapshots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No snapshots yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run a daily snapshot from the Search page',
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
                      itemCount: _snapshots.length,
                      itemBuilder: (context, index) {
                        final snapshot = _snapshots[index];
                        return _SnapshotCard(snapshot: snapshot);
                      },
                    ),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final Snapshot snapshot;

  const _SnapshotCard({required this.snapshot});

  Color _getStatusColor() {
    switch (snapshot.status) {
      case SnapshotStatus.running:
        return Colors.blue;
      case SnapshotStatus.completed:
        return Colors.green;
      case SnapshotStatus.failed:
        return Colors.red;
      case SnapshotStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (snapshot.status) {
      case SnapshotStatus.running:
        return Icons.sync;
      case SnapshotStatus.completed:
        return Icons.check_circle;
      case SnapshotStatus.failed:
        return Icons.error;
      case SnapshotStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(snapshot.snapshotDate),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF8F00),
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(snapshot.snapshotDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFF8F00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            snapshot.searchTerms,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(),
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  snapshot.status.name.toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats
                      Row(
                        children: [
                          _StatBadge(
                            icon: Icons.search,
                            label: '${snapshot.artifactsFound} found',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            icon: Icons.download,
                            label: '${snapshot.artifactsDownloaded} downloaded',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            icon: Icons.new_releases,
                            label: '${snapshot.newArtifacts} new',
                            color: const Color(0xFFFF8F00),
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            icon: Icons.content_copy,
                            label: '${snapshot.duplicatesSkipped} skipped',
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Footer
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('HH:mm').format(snapshot.startedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (snapshot.completedAt != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Duration: ${snapshot.durationFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${snapshot.institutionsUsed.length} sources',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (snapshot.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snapshot.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
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

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
