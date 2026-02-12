import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const String _qneuraUrl = 'https://qneura.ai';
  static const String _mitLicenseUrl = 'https://opensource.org/licenses/MIT';

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
                  'Agreement to Terms',
                  'By downloading, installing, or using Zephaniah ("the Application"), you agree to be bound by these Terms of Service. '
                      'If you do not agree to these terms, please do not use the Application.',
                ),

                _buildSection(
                  theme,
                  'MIT License',
                  'Zephaniah is open-source software released under the MIT License. This means:\n\n'
                      '• You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software\n'
                      '• The software is provided "as is", without warranty of any kind, express or implied\n'
                      '• The authors or copyright holders shall not be liable for any claim, damages, or other liability',
                ),

                // MIT License Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MIT License Text',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Copyright (c) 2026 Shlomo Kashani / Qneura.ai\n\n'
                          'Permission is hereby granted, free of charge, to any person obtaining a copy '
                          'of this software and associated documentation files (the "Software"), to deal '
                          'in the Software without restriction, including without limitation the rights '
                          'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                          'copies of the Software, and to permit persons to whom the Software is '
                          'furnished to do so, subject to the following conditions:\n\n'
                          'The above copyright notice and this permission notice shall be included in all '
                          'copies or substantial portions of the Software.\n\n'
                          'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
                          'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
                          'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
                          'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
                          'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
                          'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
                          'SOFTWARE.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _launchUrl(_mitLicenseUrl),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('View MIT License on OSI'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  theme,
                  'Use of the Application',
                  'You agree to use the Application only for lawful purposes and in accordance with these Terms. You agree not to:\n\n'
                      '• Use the Application in any way that violates any applicable laws or regulations\n'
                      '• Use the Application to download, store, or distribute illegal content\n'
                      '• Attempt to interfere with or disrupt the integrity of any external services accessed through the Application',
                ),

                _buildSection(
                  theme,
                  'Disclaimer of Warranties',
                  'THE APPLICATION IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT ANY WARRANTIES OF ANY KIND, '
                      'EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT:\n\n'
                      '• The Application will meet your specific requirements\n'
                      '• The Application will be uninterrupted, timely, secure, or error-free\n'
                      '• The results obtained from using the Application will be accurate or reliable\n'
                      '• Any errors in the Application will be corrected',
                ),

                _buildSection(
                  theme,
                  'Limitation of Liability',
                  'IN NO EVENT SHALL THE AUTHORS, COPYRIGHT HOLDERS, OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, '
                      'INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF '
                      'SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED '
                      'AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR '
                      'OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.',
                ),

                _buildSection(
                  theme,
                  'User Responsibility',
                  'You are solely responsible for:\n\n'
                      '• Ensuring your use of the Application complies with all applicable laws in your jurisdiction\n'
                      '• The content you download and how you use it\n'
                      '• Maintaining the security of your local device and stored data\n'
                      '• Any consequences arising from your use of the Application',
                ),

                _buildSection(
                  theme,
                  'Third-Party Content',
                  'The Application facilitates access to publicly available archives hosted by third parties. '
                      'We do not control, endorse, or assume responsibility for any third-party content. '
                      'Your use of third-party services is subject to their respective terms and policies.',
                ),

                _buildSection(
                  theme,
                  'Changes to Terms',
                  'We reserve the right to modify these Terms at any time. Changes will be reflected in the Application '
                      'with an updated "Last updated" date. Your continued use of the Application after any changes constitutes '
                      'acceptance of the new Terms.',
                ),

                _buildSection(
                  theme,
                  'Governing Law',
                  'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which '
                      'the copyright holder resides, without regard to its conflict of law provisions.',
                ),

                _buildSection(
                  theme,
                  'Contact',
                  'If you have any questions about these Terms of Service, please contact us through our website.',
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
                          'Qneura.ai',
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
