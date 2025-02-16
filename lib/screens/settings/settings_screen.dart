import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _sectionTitle(context, 'Account & Sync'),
          _buildSettingsTile(
            context,
            title: 'Account & Profile',
            icon: Iconsax.user,
            subtitle: 'AniList integration, profile settings',
            onTap: () => context.push('/settings/profile'),
          ),
          const Divider(height: 1),

          _sectionTitle(context, 'Playback & Content'),
          _buildSettingsTile(
            context,
            title: 'Video Player',
            icon: Iconsax.video_play,
            subtitle: 'Playback preferences, subtitles, episode threshold',
            onTap: () => context.push('/settings/player'),
          ),
          const Divider(height: 1),

          _sectionTitle(context, 'Sources & Downloads'),
          _buildSettingsTile(
            context,
            title: 'Anime Sources',
            icon: Iconsax.play,
            subtitle: 'Anime providers configuration',
            onTap: () => context.push('/settings/providers'),
          ),
          // Uncomment when downloads are ready
          // _buildSettingsTile(
          //   context,
          //   title: 'Download Settings',
          //   icon: Iconsax.document_download,
          //   subtitle: 'Video quality, storage location',
          //   notAvailable: true,
          //   onTap: () => context.push('/settings/downloads'),
          // ),
          const Divider(height: 1),

          _sectionTitle(context, 'Appearance'),
          _buildSettingsTile(
            context,
            title: 'Appearance',
            icon: Iconsax.brush_2,
            subtitle: 'Theme and display settings',
            onTap: () => context.push('/settings/appearance'),
          ),
          const Divider(height: 1),

          _sectionTitle(context, 'Other'),
          _buildSettingsTile(
            context,
            title: 'About',
            icon: Iconsax.info_circle,
            subtitle: 'App version, licenses',
            onTap: () => context.push('/settings/about'),
          ),
          _buildSettingsTile(
            context,
            title: 'Help & Support',
            icon: Iconsax.message_question,
            subtitle: 'FAQs, contact support',
            onTap: () => context.push('/settings/support'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    bool notAvailable = false,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: notAvailable ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      decoration: notAvailable
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
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
}
