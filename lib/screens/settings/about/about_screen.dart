import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAppHeader(context),
          const SizedBox(height: 24),
          _buildDeveloperCard(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Support & Legal'),
                const SizedBox(height: 12),
                _buildLinksList(context),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final info = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/icons/app_icon-modified-2.png',
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'ShonenX',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info != null
                    ? 'Version ${info.version} (${info.buildNumber})'
                    : 'Loading version info...',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Iconsax.code_circle,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Darkx',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lead Developer',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'ShonenX is a passion project created to provide anime and manga enthusiasts with a seamless experience to discover and enjoy their favorite content.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSocialButton(
                    context,
                    Iconsax.code,
                    () => launchUrl(Uri.parse('https://github.com/Darkx-dev')),
                  ),
                  const SizedBox(width: 12),
                  _buildSocialButton(
                    context,
                    Iconsax.message,
                    () => launchUrl(Uri.parse('mailto:developer@shonenx.app')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: theme.colorScheme.primary.withOpacity(0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksList(BuildContext context) {
    final items = [
      _LinkItem(
        icon: Iconsax.code,
        title: 'GitHub Repository',
        subtitle: 'Star us and contribute to the project',
        url: 'https://github.com/Darkx-dev/ShonenX',
      ),
      _LinkItem(
        icon: Iconsax.message_question,
        title: 'Report an Issue',
        subtitle: 'Help us improve by reporting bugs',
        url: 'https://github.com/Darkx-dev/ShonenX/issues',
      ),
      _LinkItem(
        icon: Iconsax.document_text,
        title: 'Terms of Service',
        subtitle: 'Read our terms of service',
        onTap: () => context.push('/settings/about/terms'),
        disabled: true,
      ),
      _LinkItem(
        icon: Iconsax.shield_tick,
        title: 'Privacy Policy',
        subtitle: 'Learn how we handle your data',
        onTap: () => context.push('/settings/about/privacy'),
        disabled: true,
      ),
      _LinkItem(
        icon: Iconsax.code,
        title: 'Open Source Licenses',
        subtitle: 'View third-party libraries licenses',
        onTap: () => showLicensePage(context: context),
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildLinkItem(context, item);
      },
    );
  }

  Widget _buildLinkItem(BuildContext context, _LinkItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    void handleTap() {
      if (item.disabled) return;

      if (item.onTap != null) {
        item.onTap!();
      } else if (item.url != null) {
        launchUrl(Uri.parse(item.url!));
      }
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.disabled
              ? Colors.grey.withOpacity(0.2)
              : colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: item.disabled ? null : handleTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.disabled
                      ? Colors.grey.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.disabled ? Colors.grey : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            item.disabled ? Colors.grey : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.disabled
                            ? Colors.grey.withOpacity(0.7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color:
                    item.disabled ? Colors.grey.withOpacity(0.3) : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.heart,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Made with passion for anime fans',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2025 ShonenX. All rights reserved.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _LinkItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? url;
  final VoidCallback? onTap;
  final bool disabled;

  _LinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.url,
    this.onTap,
    this.disabled = false,
  }) : assert(url != null || onTap != null);
}
