import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/auth_service.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

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
            content:
                const Text('Failed to connect to AniList. Please try again.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        debugPrint('Error during login: $e');
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileCard(context, ref, user, loginAnilist),
        if (user != null) ...[
          const SizedBox(height: 24),
          SettingsSection(context: context, title: 'Sync', items: [
            SettingsItem(
              icon: Iconsax.refresh_circle,
              title: 'Sync Settings',
              description: 'Configure AniList sync behavior',
              onTap: () => context.push('/settings/profile/sync'),
              disabled: true,
            ),
            SettingsItem(
              icon: Iconsax.timer_1,
              title: 'Auto Sync',
              description: 'Manage background sync settings',
              onTap: () => context.push('/settings/profile/auto-sync'),
              disabled: true,
            ),
          ]),
          SettingsSection(context: context, title: 'Lists', items: [
            SettingsItem(
              icon: Iconsax.task_square,
              title: 'List Settings',
              description: 'Customize your anime lists',
              onTap: () => context.push('/settings/profile/lists'),
              disabled: true,
            ),
            SettingsItem(
              icon: Iconsax.import,
              title: 'Import Lists',
              description: 'Import lists from other services',
              onTap: () => context.push('/settings/profile/import'),
              disabled: true,
            ),
          ]),
          SettingsSection(context: context, title: 'Account', items: [
            SettingsItem(
              icon: Iconsax.shield_tick,
              title: 'Privacy',
              description: 'Manage your privacy settings',
              onTap: () => context.push('/settings/profile/privacy'),
              disabled: true,
            ),
            SettingsItem(
              icon: Iconsax.document_download,
              title: 'Data & Storage',
              description: 'Manage app data and cache',
              onTap: () => context.push('/settings/profile/data'),
              disabled: true,
            ),
          ]),
        ],
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    Future<void> Function() loginAnilist,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                    ?.borderRadius ??
                BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: user != null
            ? Row(
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: user.avatar != null
                            ? CachedNetworkImage(
                                imageUrl: user.avatar!,
                                fit: BoxFit.cover,
                                width: 48,
                                height: 48,
                                placeholder: (context, url) => Container(
                                  width: 48,
                                  height: 48,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  Iconsax.user,
                                  color: theme.colorScheme.primary,
                                  size: 24,
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Iconsax.verify5,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Connected to AniList',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
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
                      backgroundColor:
                          theme.colorScheme.error.withValues(alpha: 0.1),
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.profile_add,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect to AniList',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sync your anime progress and lists',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: loginAnilist,
                    icon: const Icon(Iconsax.login),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
