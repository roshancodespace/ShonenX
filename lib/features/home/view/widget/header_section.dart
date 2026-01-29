import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/model/user.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/home/view/widget/search_model.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/utils/greeting_methods.dart';

class HeaderSection extends ConsumerWidget {
  final bool isDesktop;
  const HeaderSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlatform = ref.watch(
      authProvider.select((s) => s.activePlatform),
    );
    final user = ref.watch(
      authProvider.select(
        (s) =>
            activePlatform == AuthPlatform.anilist ? s.anilistUser : s.malUser,
      ),
    );
    final useNewUI = ref.read(experimentalProvider.select((s) => s.newUI));
    final colorScheme = Theme.of(context);
    return Column(
      children: [
        SizedBox(height: MediaQuery.viewPaddingOf(context).top),

        if (!useNewUI) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: UserProfileCard(user: user)),
              const SizedBox(width: 10),
              ActionPanel(isDesktop: isDesktop),
            ],
          ),
          const SizedBox(height: 10),
          const _DiscoverCard(),
        ]
        // NEW UI
        else ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => context.push('/settings/account/profile'),
                  child: _UserAvatar(user: user),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: VerticalDivider(
                    color: colorScheme.primaryColor,
                    thickness: 1,
                    width: 15,
                    indent: 2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${getGreeting()},',
                      style: TextStyle(color: colorScheme.primaryColor),
                    ),
                    Text(
                      user?.name ?? "Guest",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const Spacer(),
                _NewsActionBadge(),
                const SizedBox(width: 10),
                _ActionButton(
                  icon: Icons.settings_rounded,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HeaderBaseCard(
      onTap: () => context.go('/browse'),
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(0.15),
          theme.colorScheme.primary.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          _buildLeadingIcon(theme),
          const SizedBox(width: 16),
          const Expanded(child: _DiscoverTextContent()),
          const _NewsActionBadge(),
          const SizedBox(width: 8),
          Icon(
            Iconsax.arrow_right_3,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Iconsax.discover_1,
        color: theme.colorScheme.onPrimary,
        size: 22,
      ),
    );
  }
}

class _DiscoverTextContent extends StatelessWidget {
  const _DiscoverTextContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover Anime',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Find your next favorite series',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _NewsActionBadge extends ConsumerWidget {
  const _NewsActionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final newsCount = ref.watch(
      newsProvider.select(
        (state) => state.value?.where((n) => !n.isRead).length ?? 0,
      ),
    );

    return IconButton(
      onPressed: () => context.push('/news'),
      icon: Badge(
        isLabelVisible: newsCount > 0,
        label: Text(
          '$newsCount',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        child: const Icon(Iconsax.document_text),
      ),
      tooltip: 'Latest News',
    );
  }
}

class UserProfileCard extends StatelessWidget {
  final AuthUser? user;
  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HeaderBaseCard(
      color: theme.colorScheme.surface,
      onTap: () => context.push(
        user != null ? '/settings/account/profile' : '/settings/account',
      ),
      child: Row(
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null ? getGreeting() : 'Welcome!',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  user?.name ?? 'Guest',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AuthUser? user;
  const _UserAvatar({this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    );

    if (user == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: decoration,
        child: Icon(Iconsax.user, color: theme.colorScheme.primary),
      );
    }

    return Hero(
      tag: 'user-avatar',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: user!.avatarUrl ?? '',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: decoration.color,
            child: const Icon(Icons.person),
          ),
          placeholder: (_, __) => Container(color: decoration.color),
        ),
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  final bool isDesktop;
  const ActionPanel({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{
      for (var key in LogicalKeyboardKey.knownLogicalKeys)
        if (key.keyLabel.length == 1 &&
            RegExp(r'[a-zA-Z0-9]').hasMatch(key.keyLabel))
          SingleActivator(key): const OpenSearchIntent(),
    };

    return FocusableActionDetector(
      autofocus: true,
      shortcuts: shortcuts,
      actions: {
        OpenSearchIntent: CallbackAction<OpenSearchIntent>(
          onInvoke: (_) => showSearchModal(context),
        ),
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop) ...[
            _ActionButton(
              icon: Iconsax.search_normal,
              onTap: () => showSearchModal(context),
            ),
            const SizedBox(width: 8),
          ],
          const _ActionButton(icon: Iconsax.setting_2, route: '/settings'),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.route, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap ?? (route != null ? () => context.push(route!) : null),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _HeaderBaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  const _HeaderBaseCard({
    required this.child,
    this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: color ?? Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(gradient: gradient),
              child: Padding(padding: const EdgeInsets.all(12), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}
