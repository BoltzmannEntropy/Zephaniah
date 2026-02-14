import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const String _qneuraUrl = 'https://qneura.ai/apps.html';
  static const String _licenseOverviewUrl =
      'https://github.com/BoltzmannEntropy/Zephaniah/blob/main/LICENSE.md';

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
        title: const Text('Terms of Service'),
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
                        Icons.description_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Terms of Service',
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
                  '1. Acceptance of Terms',
                  'By downloading, installing, or using Zephaniah (the "Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the Service. Additional guidelines may apply to specific features and are incorporated by reference.',
                ),

                _buildSection(
                  theme,
                  '2. Description of Service',
                  'Zephaniah is an archive search and download tool designed to help researchers collect and organize public records. The Service allows you to search sources, manage downloads, and store research snapshots locally.',
                ),

                _buildSection(
                  theme,
                  '3. User Conduct',
                  'You agree to use the Service only for lawful purposes. Do not use the Service to access content you do not have rights to use, to impersonate others, or to distribute illegal content.',
                ),

                _buildSection(
                  theme,
                  '4. Intellectual Property',
                  'The Service and its original content (excluding user-provided content) are owned by QNeura.ai and its licensors. You retain ownership of your content. Nothing in these terms grants you rights to use QNeura.ai trademarks or branding without permission.',
                ),

                _buildSection(
                  theme,
                  '5. Automated Processing Disclaimer',
                  'Automated extraction, filtering, or summarization features may be inaccurate or incomplete. You should verify important information using original sources.',
                ),

                _buildSection(
                  theme,
                  '6. Disclaimer of Warranties',
                  'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.',
                ),

                _buildSection(
                  theme,
                  '7. Limitation of Liability',
                  'IN NO EVENT SHALL QNEURA.AI BE LIABLE FOR ANY DAMAGES (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF DATA OR PROFIT, OR DUE TO BUSINESS INTERRUPTION) ARISING OUT OF THE USE OR INABILITY TO USE THE SERVICE.',
                ),

                _buildSection(
                  theme,
                  '8. Changes to Terms',
                  'We may update these Terms from time to time. Continued use of the Service after changes constitutes acceptance of the updated terms.',
                ),

                _buildSection(
                  theme,
                  '9. Contact Us',
                  'If you have any questions about these Terms, please contact solomon@qneura.ai or visit https://qneura.ai/apps.html.',
                ),

                _buildSection(
                  theme,
                  '10. External Content Sources',
                  'The Service may provide access to public archives or third-party sources. These materials are provided by their respective owners and are subject to their own terms. You are responsible for ensuring your use complies with applicable laws and third-party terms.',
                ),

                _buildSection(
                  theme,
                  '11. Apple Standard EULA',
                  'If you download Zephaniah via the Apple App Store, the Apple Standard EULA applies: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/.',
                ),

                _buildSection(
                  theme,
                  '12. License & Distribution',
                  'Source code is licensed under the Business Source License 1.1 (see LICENSE). Official DMG/executable binaries are governed by a separate Binary Distribution License. Commercial use or redistribution of the Binary is not allowed. See $_licenseOverviewUrl for details.',
                ),

                _buildSection(
                  theme,
                  '13. Paid Features',
                  'If paid features are offered, purchases are processed by the storefront or payment provider. Subscription management and cancellations are handled through your account with that provider.',
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
