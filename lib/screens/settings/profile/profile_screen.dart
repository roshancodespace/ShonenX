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
            content: const Text('Failed to connect to AniList. Please try again.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        debugPrint('Error during login: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_1, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(context, ref, user, loginAnilist),
          if (user != null) ...[
            const SizedBox(height: 24),
            _buildSettingsSection(context, 'Sync', [
              _SettingsItem(
                icon: Iconsax.refresh_circle,
                title: 'Sync Settings',
                description: 'Configure AniList sync behavior',
                onTap: () => context.push('/settings/profile/sync'),
                disabled: true,
              ),
              _SettingsItem(
                icon: Iconsax.timer_1,
                title: 'Auto Sync',
                description: 'Manage background sync settings',
                onTap: () => context.push('/settings/profile/auto-sync'),
                disabled: true,
              ),
            ]),
            _buildSettingsSection(context, 'Lists', [
              _SettingsItem(
                icon: Iconsax.task_square,
                title: 'List Settings',
                description: 'Customize your anime lists',
                onTap: () => context.push('/settings/profile/lists'),
                disabled: true,
              ),
              _SettingsItem(
                icon: Iconsax.import,
                title: 'Import Lists',
                description: 'Import lists from other services',
                onTap: () => context.push('/settings/profile/import'),
                disabled: true,
              ),
            ]),
            _buildSettingsSection(context, 'Account', [
              _SettingsItem(
                icon: Iconsax.shield_tick,
                title: 'Privacy',
                description: 'Manage your privacy settings',
                onTap: () => context.push('/settings/profile/privacy'),
                disabled: true,
              ),
              _SettingsItem(
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
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    Future<void> Function() loginAnilist,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.5),
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
                        border: Border.all(color: colorScheme.primary, width: 2),
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
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Iconsax.user,
                                  color: colorScheme.primary,
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
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Iconsax.verify5,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Connected to AniList',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () async {
                      await ref.read(userProvider.notifier).logout(context: context);
                    },
                    icon: const Icon(Iconsax.logout),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                      foregroundColor: colorScheme.error,
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
                          colorScheme.primary.withOpacity(0.2),
                          colorScheme.primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                        Text(
                          'Connect to AniList',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sync your anime progress and lists',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: loginAnilist,
                    icon: const Icon(Iconsax.login),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shadowColor: colorScheme.shadow.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    item,
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = false);
        }
      },
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(widget.disabled ? 0.05 : 0.2),
                      colorScheme.primary.withOpacity(widget.disabled ? 0.03 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.disabled
                      ? colorScheme.onSurface.withOpacity(0.4)
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
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.disabled
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.3 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.2 : 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}