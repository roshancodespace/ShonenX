import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/auth_service.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);
    final authService = AniListAuthService();

    Future<void> loginAnilist() async {
      try {
        final code = await authService.authenticate();
        if (code != null) {
          final accessToken = await authService.getAccessToken(code);
          if (accessToken != null) {
            await ref.read(userProvider.notifier).login(accessToken);
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to AniList. Please try again.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        debugPrint('Error during login: $e');
      }
    }

    Widget buildProfileCard() {
      if (user != null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            border: Border.all(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: user.avatar != null
                        ? CachedNetworkImage(
                            imageUrl: user.avatar!,
                            fit: BoxFit.cover,
                            width: 42,
                            height: 42,
                          )
                        : Container(
                            width: 42,
                            height: 42,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Iconsax.user,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.verify5,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Connected to AniList',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () async {
                  await ref
                      .read(userProvider.notifier)
                      .logout(context: context);
                },
                icon: const Icon(Iconsax.logout),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                  foregroundColor: colorScheme.error,
                ),
              ),
            ],
          ),
        );
      }

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
                Iconsax.profile_add,
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
                    'Connect to AniList',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sync your anime progress and lists',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: loginAnilist,
              icon: const Icon(Iconsax.login),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSettingsTile({
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          buildProfileCard(),
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
              child: Text(
                'Sync',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
            buildSettingsTile(
              title: 'Sync Settings',
              subtitle: 'Configure AniList sync behavior',
              icon: Iconsax.refresh_circle,
              onTap: () => context.push('/settings/profile/sync'),
            ),
            buildSettingsTile(
              title: 'Auto Sync',
              subtitle: 'Manage background sync settings',
              icon: Iconsax.timer_1,
              onTap: () => context.push('/settings/profile/auto-sync'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
              child: Text(
                'Lists',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
            buildSettingsTile(
              title: 'List Settings',
              subtitle: 'Customize your anime lists',
              icon: Iconsax.task_square,
              onTap: () => context.push('/settings/profile/lists'),
            ),
            buildSettingsTile(
              title: 'Import Lists',
              subtitle: 'Import lists from other services',
              icon: Iconsax.import,
              onTap: () => context.push('/settings/profile/import'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
            buildSettingsTile(
              title: 'Privacy',
              subtitle: 'Manage your privacy settings',
              icon: Iconsax.shield_tick,
              onTap: () => context.push('/settings/profile/privacy'),
            ),
            buildSettingsTile(
              title: 'Data & Storage',
              subtitle: 'Manage app data and cache',
              icon: Iconsax.document_download,
              onTap: () => context.push('/settings/profile/data'),
            ),
          ],
        ],
      ),
    );
  }
}
