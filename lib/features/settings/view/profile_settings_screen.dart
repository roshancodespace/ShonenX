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
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ProfileAppBar(user: user, theme: theme),
          const SliverToBoxAdapter(child: SizedBox(height: 70)),
          SliverList(
            delegate: SliverChildListDelegate([
              Column(
                children: [
                  const SizedBox(height: 8),
                  ProfileName(user: user, theme: theme),
                  const SizedBox(height: 6),
                  PlatformBadge(activePlatform: activePlatform, theme: theme),
                  const SizedBox(height: 24),
                  ProfileStats(user: user),
                  const SizedBox(height: 32),
                  ProfileAbout(
                    user: user,
                    activePlatform: activePlatform,
                    ref: ref,
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ProfileActions(
                      activePlatform: activePlatform,
                      ref: ref,
                    ),
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
}

// App bar with banner and avatar
class ProfileAppBar extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;

  const ProfileAppBar({super.key, required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
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
            ? CachedNetworkImage(imageUrl: user.bannerImage!, fit: BoxFit.cover)
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
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 4),
              ),
              child: Hero(
                tag: 'user-avatar',
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: CachedNetworkImageProvider(user.avatarUrl!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// User name text
class ProfileName extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;

  const ProfileName({super.key, required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      user.name,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Shows the platform badge (AniList / MyAnimeList)
class PlatformBadge extends StatelessWidget {
  final AuthPlatform activePlatform;
  final ThemeData theme;

  const PlatformBadge({
    super.key,
    required this.activePlatform,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activePlatform == AuthPlatform.anilist ? 'AniList' : 'MyAnimeList',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Row of profile stats (Anime count, Episodes, Days, Score)
class ProfileStats extends StatelessWidget {
  final dynamic user;

  const ProfileStats({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Stat(label: 'Anime', value: user.animeCount?.toString() ?? '0'),
        Stat(label: 'Episodes', value: user.episodesWatched?.toString() ?? '0'),
        Stat(
          label: 'Days',
          value: ((user.minutesWatched ?? 0) / 1440).toStringAsFixed(1),
        ),
        Stat(label: 'Score', value: user.meanScore?.toString() ?? '-'),
      ],
    );
  }
}

class Stat extends StatelessWidget {
  final String label;
  final String value;

  const Stat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// About section with editable text for AniList
class ProfileAbout extends StatelessWidget {
  final dynamic user;
  final AuthPlatform activePlatform;
  final WidgetRef ref;

  const ProfileAbout({
    super.key,
    required this.user,
    required this.activePlatform,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              if (activePlatform == AuthPlatform.anilist) {
                EditAboutDialog.show(context, ref, user.about);
              }
            },
            child: Text(
              user.about?.isNotEmpty == true ? user.about! : 'No bio provided.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sign out button
class ProfileActions extends ConsumerWidget {
  final AuthPlatform activePlatform;
  final WidgetRef ref;

  const ProfileActions({
    super.key,
    required this.activePlatform,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          },
        );

        if (shouldLogout == true) {
          ref.read(authProvider.notifier).logout(activePlatform);
          if (!context.mounted) return;
          context.pop();
        }
      },
      child: const Text('Sign Out'),
    );
  }
}

// Dialog for editing user about/bio
class EditAboutDialog {
  static Future<void> show(
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
