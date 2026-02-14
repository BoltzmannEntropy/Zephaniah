import 'package:flutter/material.dart' hide LicensePage;
import 'package:url_launcher/url_launcher.dart';
import '../version.dart';
import 'license_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _websiteUrl =
      'https://boltzmannentropy.github.io/zephaniah.github.io/';
  static const String _githubUrl =
      'https://github.com/BoltzmannEntropy/Zephaniah';
  static const String _issuesUrl =
      'https://github.com/BoltzmannEntropy/Zephaniah/issues';

  // Archive source URLs
  static const Map<String, String> _sourceUrls = {
    'Internet Archive': 'https://archive.org/download/Epstein-Data-Sets-So-Far',
    'Google Drive': 'https://drive.google.com/drive/folders/18tIY9QEGUZe0q_AFAxoPnnVBCWbqHm2p',
    'GitHub Index': 'https://github.com/yung-megafone/Epstein-Files',
    'Reddit': 'https://www.reddit.com/r/Epstein/',
  };

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
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
                  Icons.archive_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // App name
              Text(
                'Zephaniah',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Version
              Text(
                'Version $appVersion',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                versionName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Epstein Files Archive Downloader & Library',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Links section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Links',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _launchUrl(_websiteUrl),
                        icon: const Icon(Icons.language),
                        label: const Text('Website'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _launchUrl(_githubUrl),
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _launchUrl(_issuesUrl),
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Report Issue'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('Privacy Policy'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TermsOfServicePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Terms of Service'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LicensePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.balance_outlined),
                        label: const Text('License'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Archive Sources section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Archive Sources',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click to visit data sources',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSourceChip('Internet Archive', Colors.blue, _sourceUrls['Internet Archive']!),
                          _buildSourceChip('Google Drive', Colors.amber.shade700, _sourceUrls['Google Drive']!),
                          _buildSourceChip('GitHub Index', Colors.grey.shade700, _sourceUrls['GitHub Index']!),
                          _buildSourceChip('Reddit', Colors.deepOrange, _sourceUrls['Reddit']!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Powered By section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Powered By',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTechChip('Flutter', Colors.blue, 'https://flutter.dev'),
                          _buildTechChip('Syncfusion PDF', Colors.teal, 'https://pub.dev/packages/syncfusion_flutter_pdfviewer'),
                          _buildTechChip('media_kit', Colors.purple, 'https://pub.dev/packages/media_kit'),
                          _buildTechChip('SQLite', Colors.green, 'https://sqlite.org'),
                        ],
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
                  padding: const EdgeInsets.all(16),
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
                        'This application downloads publicly available documents from community archives. '
                        'Users are responsible for complying with all applicable laws. '
                        'The developers assume no liability for misuse of this tool.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Footer
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Source: BSL 1.1 · Binary: Binary Distribution License',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '2026 Shlomo Kashani / QNeura.ai',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceChip(String label, Color color, String url) {
    return ActionChip(
      onPressed: () => _launchUrl(url),
      avatar: Icon(Icons.open_in_new, size: 16, color: Colors.white.withValues(alpha: 0.9)),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
      tooltip: 'Open $label',
    );
  }

  Widget _buildTechChip(String label, Color color, String url) {
    return ActionChip(
      onPressed: () => _launchUrl(url),
      avatar: Icon(Icons.open_in_new, size: 14, color: Colors.white.withValues(alpha: 0.8)),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.8),
      side: BorderSide.none,
      tooltip: 'Visit $label',
    );
  }
}
