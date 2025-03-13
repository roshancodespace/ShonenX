import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(context: context, title: 'Support', items: [
              SettingsItem(
                disabled: true,
                title: 'FAQ',
                icon: Iconsax.message_question,
                description: 'Frequently asked questions',
                onTap: () {},
              ),
              SettingsItem(
                disabled: true,
                title: 'Contact Support',
                icon: Iconsax.message_text,
                description: 'Get help from our team',
                onTap: () {},
              ),
            ]),
            SettingsSection(context: context, title: 'Community', items: [
              SettingsItem(
                title: 'Discord Server',
                icon: Iconsax.message,
                description: 'Join our community',
                onTap: () =>
                    launchUrl(Uri.parse('https://discord.gg/zCScP7Y6')),
              ),
              SettingsItem(
                title: 'Report an Issue',
                icon: Iconsax.warning_2,
                description: 'Help us improve the app',
                onTap: () => launchUrl(
                    Uri.parse('https://github.com/Darkx-dev/ShonenX/issues')),
              ),
            ]),
            SettingsSection(context: context, title: 'Resources', items: [
              SettingsItem(
                disabled: true,
                title: 'Documentation',
                icon: Iconsax.document_text,
                description: 'Learn how to use the app',
                onTap: () {},
              ),
              SettingsItem(
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
