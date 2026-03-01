import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';

class McpPage extends StatefulWidget {
  const McpPage({super.key});

  @override
  State<McpPage> createState() => _McpPageState();
}

class _McpPageState extends State<McpPage> {
  final McpServer _mcp = McpServer();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mcp.addListener(_onMcpChanged);
    _hostController.text = _mcp.host;
    _portController.text = _mcp.port.toString();
  }

  @override
  void dispose() {
    _mcp.removeListener(_onMcpChanged);
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onMcpChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleServer() async {
    if (_mcp.isRunning) {
      await _mcp.stop();
    } else {
      final host = _hostController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 8088;
      await _mcp.start(host: host, port: port);
    }
  }

  void _copyConfig() {
    final config = _mcp.generateClaudeConfig();
    Clipboard.setData(ClipboardData(text: config));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.hub_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MCP Integration',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(_mcp.isRunning ? 'Running' : 'Stopped'),
                    backgroundColor: _mcp.isRunning
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: _mcp.isRunning
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    avatar: Icon(
                      _mcp.isRunning ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _mcp.isRunning
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Connect Zephaniah to Claude Code via Model Context Protocol',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Server Status Card
              _buildServerStatusCard(theme, colorScheme),
              const SizedBox(height: 24),

              // Available Tools Card
              _buildToolsCard(theme, colorScheme),
              const SizedBox(height: 24),

              // Claude Code Setup Card
              _buildClaudeCodeSetupCard(theme, colorScheme),
              const SizedBox(height: 24),

              // Server Logs Card
              _buildLogsCard(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerStatusCard(ThemeData theme, ColorScheme colorScheme) {
    final uptime = _mcp.uptime;
    String uptimeText = 'Not running';
    if (uptime != null) {
      final hours = uptime.inHours;
      final minutes = uptime.inMinutes % 60;
      final seconds = uptime.inSeconds % 60;
      uptimeText = '${hours}h ${minutes}m ${seconds}s';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'MCP Server',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Configuration Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    enabled: !_mcp.isRunning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_mcp.isRunning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _mcp.isRunning ? _mcp.address : 'http://${_hostController.text}:${_portController.text}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uptime',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          uptimeText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requests',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${_mcp.requestCount}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _toggleServer,
                  icon: Icon(_mcp.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_mcp.isRunning ? 'Stop Server' : 'Start Server'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _mcp.isRunning ? Colors.red : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (_mcp.isRunning)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _mcp.stop();
                      await _mcp.start(
                        host: _hostController.text,
                        port: int.tryParse(_portController.text) ?? 8088,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsCard(ThemeData theme, ColorScheme colorScheme) {
    final tools = _mcp.tools;

    // Group tools by category
    final categories = <String, List<McpTool>>{
      'Health & Status': tools.where((t) => t.name.contains('health') || t.name.contains('system') || t.name.contains('info')).toList(),
      'Library': tools.where((t) => t.name.contains('library') || t.name.contains('datasets')).toList(),
      'Archives': tools.where((t) => t.name.contains('archive')).toList(),
      'Search & Download': tools.where((t) => t.name.contains('search') || t.name.contains('download') || t.name.contains('enqueue')).toList(),
      'Database': tools.where((t) => t.name.contains('history') || t.name.contains('artifacts')).toList(),
      'Settings & Logs': tools.where((t) => t.name.contains('settings') || t.name.contains('logs')).toList(),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Available Tools',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text('${tools.length} tools'),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...categories.entries.where((e) => e.value.isNotEmpty).map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...entry.value.map((tool) => _buildToolTile(tool, theme, colorScheme)),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile(McpTool tool, ThemeData theme, ColorScheme colorScheme) {
    final properties = tool.inputSchema['properties'] as Map<String, dynamic>? ?? {};
    final required = (tool.inputSchema['required'] as List<dynamic>?)?.cast<String>() ?? [];

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        tool.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        tool.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.description,
                style: theme.textTheme.bodySmall,
              ),
              if (properties.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Parameters:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...properties.entries.map((param) {
                  final paramInfo = param.value as Map<String, dynamic>;
                  final isRequired = required.contains(param.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          param.key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: isRequired ? colorScheme.error : colorScheme.onSurface,
                          ),
                        ),
                        if (isRequired)
                          Text(
                            '*',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        Text(
                          ': ${paramInfo['type'] ?? 'any'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (paramInfo['description'] != null)
                          Expanded(
                            child: Text(
                              ' - ${paramInfo['description']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaudeCodeSetupCard(ThemeData theme, ColorScheme colorScheme) {
    final config = _mcp.generateClaudeConfig();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Claude Code Setup',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Add this configuration to your Claude Code settings to enable MCP integration:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SelectableText(
                config,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                FilledButton.icon(
                  onPressed: _copyConfig,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Configuration'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Paste this config into your Claude Code settings.json under "mcpServers"',
                        ),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure the MCP server is running before using Claude Code with Zephaniah.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(ThemeData theme, ColorScheme colorScheme) {
    final logs = _mcp.recentLogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Server Logs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'No logs yet. Start the server to see activity.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final log = logs[logs.length - 1 - index];
                        return Text(
                          log,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
