import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String _qneuraUrl = 'https://qneura.ai/apps.html';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Privacy Policy',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: February 2026',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSection(
                  theme,
                  'Introduction',
                  'Zephaniah is a local-first application designed with your privacy as a core principle. '
                      'This Privacy Policy explains how we handle information when you use the app.',
                ),

                _buildSection(
                  theme,
                  'Data Collection',
                  'Zephaniah does not collect personal information by default. The application operates '
                      'primarily on your local device. Specifically:\n\n'
                      '• No usage analytics or telemetry data is gathered\n'
                      '• No cookies or tracking technologies are used\n'
                      '• No data is shared with third parties by the app',
                ),

                _buildSection(
                  theme,
                  'Local Data Storage',
                  'All data processed by Zephaniah is stored locally on your device:\n\n'
                      '• Downloaded files are saved to your chosen local directory\n'
                      '• Application settings are stored in local preferences\n'
                      '• Database information is kept in local SQLite storage\n'
                      '• No data is synchronized to cloud services by the application',
                ),

                _buildSection(
                  theme,
                  'Network Activity',
                  'Zephaniah only connects to the internet for the following purposes:\n\n'
                      '• Downloading publicly available archive files from sources you explicitly request\n'
                      '• Fetching archive metadata and file listings\n\n'
                      'Your requests are sent to those public sources to complete the download.',
                ),

                _buildSection(
                  theme,
                  'Third-Party Services',
                  'The application downloads files from publicly available archives (Internet Archive, etc.). '
                      'When accessing these services, their respective privacy policies apply. '
                      'Zephaniah itself does not integrate any third-party analytics, advertising, or tracking services.',
                ),

                _buildSection(
                  theme,
                  'Data Security',
                  'Since all data remains on your local device, you maintain full control over its security. '
                      'We recommend following standard security practices for your operating system and file storage.',
                ),

                _buildSection(
                  theme,
                  'Children\'s Privacy',
                  'This application is not directed at children under the age of 13. '
                      'As we do not collect any personal data, we do not knowingly collect information from children.',
                ),

                _buildSection(
                  theme,
                  'Changes to This Policy',
                  'We may update this Privacy Policy from time to time. Any changes will be reflected in the application '
                      'with an updated "Last updated" date. Continued use of the application after changes constitutes acceptance of the updated policy.',
                ),

                _buildSection(
                  theme,
                  'Contact',
                  'If you have any questions about this Privacy Policy, please contact solomon@qneura.ai or visit https://qneura.ai/apps.html.',
                ),

                const SizedBox(height: 24),

                // Author attribution
                Center(
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Published by',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _launchUrl(_qneuraUrl),
                        child: Text(
                          'QNeura.ai',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
