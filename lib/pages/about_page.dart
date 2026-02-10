import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Zephaniah',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                'Public document search and archival tool for investigating institutional records.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Features
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FeatureItem(
                        icon: Icons.search,
                        title: 'Multi-Source Search',
                        description:
                            'Search across multiple government and institutional sources',
                      ),
                      _FeatureItem(
                        icon: Icons.download,
                        title: 'Bulk Download',
                        description:
                            'Download multiple documents with queue management',
                      ),
                      _FeatureItem(
                        icon: Icons.camera_alt,
                        title: 'Daily Snapshots',
                        description:
                            'Automated daily archival of new documents',
                      ),
                      _FeatureItem(
                        icon: Icons.picture_as_pdf,
                        title: 'Integrated Viewer',
                        description:
                            'View PDFs, audio, and video files in-app',
                      ),
                      _FeatureItem(
                        icon: Icons.extension,
                        title: 'MCP Extensible',
                        description:
                            'Add custom search providers via MCP protocol',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Licenses
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Licenses & Credits',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LicenseItem(
                        name: 'PDF Viewer',
                        library: 'Syncfusion Flutter PDF Viewer',
                        license: 'Syncfusion Community License',
                        note:
                            'Free for individuals and businesses with less than \$1M annual revenue.',
                        onTap: () =>
                            _launchUrl('https://www.syncfusion.com/license'),
                      ),
                      const Divider(height: 24),
                      _LicenseItem(
                        name: 'Media Player',
                        library: 'media_kit',
                        license: 'MIT License',
                        onTap: () => _launchUrl(
                            'https://github.com/media-kit/media-kit'),
                      ),
                      const Divider(height: 24),
                      _LicenseItem(
                        name: 'Database',
                        library: 'SQLite',
                        license: 'Public Domain',
                        onTap: () =>
                            _launchUrl('https://www.sqlite.org/copyright.html'),
                      ),
                      const Divider(height: 24),
                      _LicenseItem(
                        name: 'Framework',
                        library: 'Flutter',
                        license: 'BSD 3-Clause License',
                        onTap: () => _launchUrl(
                            'https://github.com/flutter/flutter/blob/master/LICENSE'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Disclaimer
              Card(
                color: Colors.amber.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 20,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Disclaimer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This application is designed for legitimate research and journalistic purposes. '
                        'Users are responsible for complying with all applicable laws and terms of service '
                        'when accessing and downloading public documents. The developers assume no liability '
                        'for misuse of this tool.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer
              Text(
                'Built with Flutter',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
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

class _LicenseItem extends StatelessWidget {
  final String name;
  final String library;
  final String license;
  final String? note;
  final VoidCallback onTap;

  const _LicenseItem({
    required this.name,
    required this.library,
    required this.license,
    this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              library,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              license,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
