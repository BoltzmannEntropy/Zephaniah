import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';

class LogsPanel extends StatefulWidget {
  const LogsPanel({super.key});

  @override
  State<LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<LogsPanel> {
  final LogService _log = LogService();
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;
  LogLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _log.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    _log.removeListener(_onLogChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogChanged() {
    if (mounted) {
      setState(() {});
      // Auto-scroll to bottom
      if (_isExpanded && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  void _copyAllLogs(List<LogEntry> entries) {
    final text = entries.map((e) {
      final time = '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}:${e.timestamp.second.toString().padLeft(2, '0')}';
      return '$time ${e.level.name.toUpperCase()} [${e.source}] ${e.message}';
    }).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  void _copyLogEntry(LogEntry entry) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
    final text = '$time ${entry.level.name.toUpperCase()} [${entry.source}] ${entry.message}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log entry copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final entries = _filterLevel != null
        ? _log.filterByLevel(_filterLevel!)
        : _log.recentEntries;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    Icons.terminal_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logs',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_log.entries.length})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (_isExpanded) ...[
                    // Level filters
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterLevel == null,
                      onTap: () => setState(() => _filterLevel = null),
                    ),
                    _FilterChip(
                      label: 'Error',
                      isSelected: _filterLevel == LogLevel.error,
                      color: Colors.red,
                      onTap: () =>
                          setState(() => _filterLevel = LogLevel.error),
                    ),
                    _FilterChip(
                      label: 'Warn',
                      isSelected: _filterLevel == LogLevel.warning,
                      color: Colors.orange,
                      onTap: () =>
                          setState(() => _filterLevel = LogLevel.warning),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => _copyAllLogs(entries),
                      tooltip: 'Copy all logs',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: _log.clear,
                      tooltip: 'Clear logs',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
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
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final color = _getLevelColor(entry.level);

                  return GestureDetector(
                    onSecondaryTapUp: (details) {
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        items: [
                          PopupMenuItem(
                            onTap: () => _copyLogEntry(entry),
                            child: const Row(
                              children: [
                                Icon(Icons.copy, size: 16),
                                SizedBox(width: 8),
                                Text('Copy'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          Container(
                            width: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              entry.level.name.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              '[${entry.source}]',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              entry.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
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
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? effectiveColor : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? effectiveColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
