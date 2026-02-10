import 'package:flutter/material.dart';
import '../services/services.dart';

class McpPage extends StatefulWidget {
  const McpPage({super.key});

  @override
  State<McpPage> createState() => _McpPageState();
}

class _McpPageState extends State<McpPage> {
  final McpService _mcp = McpService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _mcp.addListener(_onMcpChanged);
  }

  @override
  void dispose() {
    _mcp.removeListener(_onMcpChanged);
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onMcpChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final success = await _mcp.testConnection(_urlController.text);

    setState(() {
      _isTesting = false;
      _testResult = success ? 'Connection successful!' : 'Connection failed';
    });
  }

  Future<void> _addProvider() async {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and URL')),
      );
      return;
    }

    await _mcp.addProvider(
      name: _nameController.text,
      endpointUrl: _urlController.text,
    );

    _nameController.clear();
    _urlController.clear();
    _testResult = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MCP provider added')),
      );
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
                Icons.extension_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'MCP Providers',
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
                  '${_mcp.connectedProviders.length}/${_mcp.providers.length} connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider list
              Expanded(
                flex: 2,
                child: _mcp.providers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.extension_off,
                              size: 64,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No MCP providers',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a provider to extend search capabilities',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _mcp.providers.length,
                        itemBuilder: (context, index) {
                          final provider = _mcp.providers[index];
                          return _ProviderCard(
                            provider: provider,
                            onToggle: (enabled) =>
                                _mcp.toggleProvider(provider.id, enabled),
                            onDelete: () => _mcp.removeProvider(provider.id),
                          );
                        },
                      ),
              ),
              const VerticalDivider(width: 1),
              // Add provider form
              SizedBox(
                width: 350,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add MCP Provider',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Provider Name',
                          hintText: 'e.g., Custom Search Engine',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Endpoint URL',
                          hintText: 'e.g., http://localhost:8010',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.wifi_tethering),
                            label: const Text('Test Connection'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _addProvider,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_testResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _testResult!.contains('successful')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testResult!.contains('successful')
                                    ? Icons.check_circle
                                    : Icons.error,
                                size: 16,
                                color: _testResult!.contains('successful')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _testResult!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _testResult!.contains('successful')
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'About MCP',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MCP (Model Context Protocol) providers extend search capabilities. Add compatible servers to include additional search engines and tools.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final McpProvider provider;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;

  const _ProviderCard({
    required this.provider,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: provider.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        provider.endpointUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: provider.enabled,
                  onChanged: onToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
              ],
            ),
            if (provider.isConnected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (provider.serverName != null)
                    _InfoBadge(
                      icon: Icons.computer,
                      label: provider.serverName!,
                    ),
                  if (provider.serverVersion != null) ...[
                    const SizedBox(width: 8),
                    _InfoBadge(
                      icon: Icons.tag,
                      label: 'v${provider.serverVersion}',
                    ),
                  ],
                  const SizedBox(width: 8),
                  _InfoBadge(
                    icon: Icons.build,
                    label: '${provider.tools.length} tools',
                  ),
                ],
              ),
              if (provider.tools.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: provider.tools.take(10).map((tool) {
                    return Chip(
                      label: Text(tool.name),
                      labelStyle: theme.textTheme.bodySmall,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
                if (provider.tools.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${provider.tools.length - 10} more tools',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
