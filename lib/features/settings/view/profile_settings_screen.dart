import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activePlatform = authState.activePlatform;
    final user = authState.userFor(activePlatform);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left_2),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/settings/account'),
                icon: const Icon(Iconsax.setting_2),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: user.bannerImage != null
                  ? CachedNetworkImage(
                      imageUrl: user.bannerImage!,
                      fit: BoxFit.cover,
                    )
                  : ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Transform.translate(
                offset: const Offset(0, 40),
                child: Container(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 4,
                      ),
                    ),
                    child: Hero(
                      tag: 'user-avatar',
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            CachedNetworkImageProvider(user.avatarUrl!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 70)),

          /// ================= CONTENT =================
          SliverList(
            delegate: SliverChildListDelegate([
              Column(
                children: [
                  const SizedBox(height: 8),

                  /// NAME
                  Text(
                    user.name,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  /// PLATFORM BADGE
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activePlatform == AuthPlatform.anilist
                          ? 'AniList'
                          : 'MyAnimeList',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// STATS
                  _buildStatsRow(context, user),

                  const SizedBox(height: 32),

                  /// ABOUT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'About',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            // if (activePlatform == AuthPlatform.anilist)
                            //   IconButton(
                            //     icon: const Icon(Icons.mode_edit, size: 20),
                            //     onPressed: () => _showEditAboutDialog(
                            //       context,
                            //       ref,
                            //       user.about,
                            //     ),
                            //   ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (activePlatform == AuthPlatform.anilist) {
                              _showEditAboutDialog(
                                context,
                                ref,
                                user.about,
                              );
                            }
                          },
                          child: Text(
                            user.about?.isNotEmpty == true
                                ? user.about!
                                : 'No bio provided.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// ACTIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildActionButtons(context, ref, activePlatform),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(context, 'Anime', user.animeCount?.toString() ?? '0'),
        _stat(context, 'Episodes', user.episodesWatched?.toString() ?? '0'),
        _stat(
          context,
          'Days',
          ((user.minutesWatched ?? 0) / 1440).toStringAsFixed(1),
        ),
        _stat(context, 'Score', user.meanScore?.toString() ?? '-'),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    AuthPlatform platform,
  ) {
    return FilledButton(
      onPressed: () async {
        final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              );
            });
        if (shouldLogout != null && shouldLogout) {
          ref.read(authProvider.notifier).logout(platform);
          if (!context.mounted) return;
          context.pop();
        }
      },
      child: const Text('Sign Out'),
    );
  }

  Future<void> _showEditAboutDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentAbout,
  ) async {
    final controller = TextEditingController(text: currentAbout);

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit About'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tell us about yourself…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(authProvider.notifier)
                  .updateAnilistProfile(about: controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
