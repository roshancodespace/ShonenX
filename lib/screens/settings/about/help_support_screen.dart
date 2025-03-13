import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

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
                title: 'FAQ',
                icon: Iconsax.message_question,
                description: 'Frequently asked questions',
                onTap: () {},
              ),
              SettingsItem(
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
                onTap: () {},
              ),
              SettingsItem(
                title: 'Report an Issue',
                icon: Iconsax.warning_2,
                description: 'Help us improve the app',
                onTap: () {},
              ),
            ]),
            SettingsSection(context: context, title: 'Resources', items: [
              SettingsItem(
                title: 'Documentation',
                icon: Iconsax.document_text,
                description: 'Learn how to use the app',
                onTap: () {},
              ),
              SettingsItem(
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
