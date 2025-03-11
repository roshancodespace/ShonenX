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
      required IconData icon,
      VoidCallback? onTap,
      bool disabled = false,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: disabled
                        ? colorScheme.onSurface.withValues(alpha: 0.1)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: disabled
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : colorScheme.primary,
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
                          color: disabled
                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: disabled
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null && !disabled)
                  Icon(
                    Iconsax.arrow_right_3,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
              ],
            ),
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
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildAppInfo(),
          const SizedBox(height: 16),
          Text(
            'Legal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          buildInfoTile(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              icon: Iconsax.document_text,
              onTap: () => context.push('/settings/about/terms'),
              disabled: true),
          buildInfoTile(
              title: 'Privacy Policy',
              subtitle: 'Learn how we handle your data',
              icon: Iconsax.shield_tick,
              onTap: () => context.push('/settings/about/privacy'),
              disabled: true),
          buildInfoTile(
            title: 'Licenses',
            subtitle: 'Open source licenses',
            icon: Iconsax.code,
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: 24),
          Text(
            'Links',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
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
            disabled: false, // Set to true to disable this item
          ),
        ],
      ),
    );
  }
}
