import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'pro_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _searchTermsController;
  late AppSettings _currentSettings;

  int _artifactCount = 0;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _currentSettings = _settings.settings;
    _searchTermsController = TextEditingController(
      text: _currentSettings.defaultSearchTerms,
    );
    _loadStats();
  }

  @override
  void dispose() {
    _searchTermsController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final count = await _db.getArtifactCount();
    final size = await _db.getTotalArtifactSize();
    if (mounted) {
      setState(() {
        _artifactCount = count;
        _totalSize = size;
      });
    }
  }

  Future<void> _saveSettings() async {
    await _settings.update(
      _currentSettings.copyWith(
        defaultSearchTerms: _searchTermsController.text,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Search Defaults
          _SectionHeader(icon: Icons.search, title: 'Search Defaults'),
          const SizedBox(height: 16),
          TextField(
            controller: _searchTermsController,
            decoration: const InputDecoration(
              labelText: 'Default Search Terms',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DropdownSetting<String>(
                  label: 'Default Search Engine',
                  value: _currentSettings.defaultSearchEngine,
                  items: SearchEngine.values.map((e) => e.code).toList(),
                  itemLabel: (code) => SearchEngine.values
                      .firstWhere((e) => e.code == code)
                      .label,
                  onChanged: (value) {
                    setState(() {
                      _currentSettings = _currentSettings.copyWith(
                        defaultSearchEngine: value,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DropdownSetting<String>(
                  label: 'Default Time Range',
                  value: _currentSettings.defaultTimeRange,
                  items: TimeRange.values
                      .where((t) => t != TimeRange.custom)
                      .map((t) => t.name)
                      .toList(),
                  itemLabel: (name) =>
                      TimeRange.values.firstWhere((t) => t.name == name).label,
                  onChanged: (value) {
                    setState(() {
                      _currentSettings = _currentSettings.copyWith(
                        defaultTimeRange: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Default File Types:', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FileType.values.map((type) {
              final isSelected = _currentSettings.defaultFileTypes.contains(
                type.extension,
              );
              return FilterChip(
                label: Text(type.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final types = List<String>.from(
                      _currentSettings.defaultFileTypes,
                    );
                    if (selected) {
                      types.add(type.extension);
                    } else {
                      types.remove(type.extension);
                    }
                    _currentSettings = _currentSettings.copyWith(
                      defaultFileTypes: types,
                    );
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Download Settings
          _SectionHeader(icon: Icons.download, title: 'Downloads'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DropdownSetting<int>(
                  label: 'Concurrent Downloads',
                  value: _currentSettings.concurrentDownloads,
                  items: const [1, 2, 3, 4, 5],
                  itemLabel: (n) => '$n',
                  onChanged: (value) {
                    setState(() {
                      _currentSettings = _currentSettings.copyWith(
                        concurrentDownloads: value,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DropdownSetting<int>(
                  label: 'Auto-retry Attempts',
                  value: _currentSettings.autoRetryAttempts,
                  items: const [0, 1, 2, 3],
                  itemLabel: (n) => '$n',
                  onChanged: (value) {
                    setState(() {
                      _currentSettings = _currentSettings.copyWith(
                        autoRetryAttempts: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Download Location'),
            subtitle: Text(_currentSettings.downloadLocation),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Snapshot Settings
          _SectionHeader(icon: Icons.camera_alt, title: 'Snapshots'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Auto-run on Launch'),
            subtitle: const Text('Automatically run snapshot when app starts'),
            value: _currentSettings.autoRunOnLaunch,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  autoRunOnLaunch: value,
                );
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 8),
          _DropdownSetting<int>(
            label: 'Snapshot Retention (days)',
            value: _currentSettings.snapshotRetentionDays,
            items: const [7, 14, 30, 60, 90, 180, 365],
            itemLabel: (n) => '$n days',
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  snapshotRetentionDays: value,
                );
              });
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // UI Settings
          _SectionHeader(icon: Icons.palette, title: 'Interface'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Download Queue'),
            subtitle: const Text('Display download progress panel'),
            value: _currentSettings.showDownloadQueue,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  showDownloadQueue: value,
                );
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show Logs Panel'),
            subtitle: const Text('Display system logs at bottom'),
            value: _currentSettings.showLogsPanel,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  showLogsPanel: value,
                );
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Pro / Licensing
          _SectionHeader(icon: Icons.workspace_premium_rounded, title: 'Pro'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_rounded),
              title: const Text('Zephaniah Pro'),
              subtitle: const Text(
                'Free app. No trial timer or paid license required.',
              ),
              trailing: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ProPage()));
                },
                child: const Text('Open Pro'),
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Storage
          _SectionHeader(icon: Icons.storage, title: 'Storage'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Artifacts',
                        value: '$_artifactCount',
                        icon: Icons.file_present,
                      ),
                      _StatItem(
                        label: 'Storage Used',
                        value: _formatBytes(_totalSize),
                        icon: Icons.storage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _db.cleanupOldArtifacts(
                            _currentSettings.snapshotRetentionDays,
                          );
                          _loadStats();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Old artifacts cleaned'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Clean Old Artifacts'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final file = await LogService().exportToFile();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Diagnostic logs exported to ${file?.path ?? "N/A"}',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.manage_search_rounded),
                        label: const Text('Export System Logs'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          Center(
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(value: item, child: Text(itemLabel(item)));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 32, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
