import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildInfoTile({
      required String title,
      required String subtitle,
      bool notAvailable = false,
      required IconData icon,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decorationStyle: TextDecorationStyle.solid,
                        decoration:
                            notAvailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Iconsax.arrow_right_3,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      );
    }

    Widget buildAppInfo() {
      return FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final info = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.primary.withValues(alpha: 0.05),
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.mobile,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ShonenX',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version ${info.version} (${info.buildNumber})',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          buildAppInfo(),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
            child: Text(
              'Legal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ),
          buildInfoTile(
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            icon: Iconsax.document_text,
            onTap: () => context.push('/settings/about/terms'),
          ),
          buildInfoTile(
            title: 'Privacy Policy',
            subtitle: 'Learn how we handle your data',
            icon: Iconsax.shield_tick,
            onTap: () => context.push('/settings/about/privacy'),
          ),
          buildInfoTile(
            title: 'Licenses',
            subtitle: 'Open source licenses',
            icon: Iconsax.code,
            onTap: () => showLicensePage(context: context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
            child: Text(
              'Links',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ),
          buildInfoTile(
            title: 'GitHub Repository',
            subtitle: 'View source code and contribute',
            icon: Iconsax.code,
            onTap: () =>
                launchUrl(Uri.parse('https://github.com/Darkx-dev/ShonenX')),
          ),
          buildInfoTile(
            title: 'Report an Issue',
            subtitle: 'Help us improve the app',
            icon: Iconsax.message_question,
            onTap: () => launchUrl(
                Uri.parse('https://github.com/Darkx-dev/ShonenX/issues')),
          ),
          // buildInfoTile(
          //   title: 'Join Discord',
          //   subtitle: 'Connect with the community',
          //   icon: Iconsax.message,
          //   onTap: () => launchUrl(Uri.parse('https://discord.gg/your-server')),
          // ),
        ],
      ),
    );
  }
}
