import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(
                compact: true,
                context: context,
                title: 'Support',
                items: [
                  SettingsItem(
                    compact: true,
                    disabled: true,
                    title: 'FAQ',
                    icon: Iconsax.message_question,
                    description: 'Frequently asked questions',
                    onTap: () {},
                  ),
                  SettingsItem(
                    compact: true,
                    disabled: true,
                    title: 'Contact Support',
                    icon: Iconsax.message_text,
                    description: 'Get help from our team',
                    onTap: () {},
                  ),
                ]),
            SettingsSection(
                compact: true,
                context: context,
                title: 'Community',
                items: [
                  SettingsItem(
                    compact: true,
                    title: 'Discord Server',
                    icon: Iconsax.message,
                    description: 'Join our community',
                    onTap: () =>
                        launchUrl(Uri.parse('https://discord.gg/zCScP7Y6')),
                  ),
                  SettingsItem(
                    compact: true,
                    title: 'Report an Issue',
                    icon: Iconsax.warning_2,
                    description: 'Help us improve the app',
                    onTap: () => launchUrl(Uri.parse(
                        'https://github.com/Darkx-dev/ShonenX/issues')),
                  ),
                ]),
            SettingsSection(
                compact: true,
                context: context,
                title: 'Resources',
                items: [
                  SettingsItem(
                    compact: true,
                    disabled: true,
                    title: 'Documentation',
                    icon: Iconsax.document_text,
                    description: 'Learn how to use the app',
                    onTap: () {},
                  ),
                  SettingsItem(
                    compact: true,
                    disabled: true,
                    title: 'Video Tutorials',
                    icon: Iconsax.video_play,
                    description: 'Watch guides and tutorials',
                    onTap: () {},
                  ),
                ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
