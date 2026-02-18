import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import '../providers/auth_notifier.dart';

class AccountAuthenticationSection extends ConsumerWidget {
  const AccountAuthenticationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);

    return Column(
      children: [
        _ServiceCard(
          platform: AuthPlatform.anilist,
          name: 'AniList',
          description: 'Track, discover, and share anime',
          logoUrl: 'https://anilist.co/img/icons/android-chrome-512x512.png',
          brandColor: const Color(0xFF02A9FF),
          state: state,
        ),
        const SizedBox(height: 8),
        _ServiceCard(
          platform: AuthPlatform.mal,
          name: 'MyAnimeList',
          description: 'Work in progress',
          logoUrl:
              'https://cdn.myanimelist.net/img/sp/icon/apple-touch-icon-256.png',
          brandColor: const Color(0xFF2E51A2),
          state: state,
        ),
        if (state.isAniListAuthenticated || state.isMalAuthenticated) ...[
          const SizedBox(height: 24),
          _PrimaryPlatformInfo(activePlatform: state.activePlatform),
        ],
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final AuthPlatform platform;
  final String name;
  final String description;
  final String logoUrl;
  final Color brandColor;
  final AuthState state;

  const _ServiceCard({
    required this.platform,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.brandColor,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthenticated = state.isAuthenticatedFor(platform);
    final isActive = state.activePlatform == platform;
    final user = state.userFor(platform);
    final isLoading = state.isLoadingFor(platform);

    return Material(
      color: isAuthenticated
          ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isActive
            ? BorderSide(color: brandColor, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(authProvider.notifier).changePlatform(platform),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _ServiceLogo(url: logoUrl, color: brandColor, size: 50),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: brandColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isAuthenticated && user != null)
                      Text(
                        '@${user.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: brandColor,
                  ),
                )
              else if (isAuthenticated)
                IconButton.filledTonal(
                  onPressed: () =>
                      _showDisconnectDialog(context, ref, name, platform),
                  icon: const Icon(Iconsax.logout),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                )
              else
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(authProvider.notifier).login(platform),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColor.withOpacity(0.1),
                    foregroundColor: brandColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisconnectDialog(
    BuildContext context,
    WidgetRef ref,
    String name,
    AuthPlatform platform,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Iconsax.warning_2),
        title: Text('Disconnect $name?'),
        content: const Text(
          'Syncing will stop immediately. Local data will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout(platform);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _ServiceLogo extends StatelessWidget {
  final String url;
  final Color color;
  final double size;

  const _ServiceLogo({
    required this.url,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          errorWidget: (_, __, ___) => Icon(Iconsax.image, color: color),
        ),
      ),
    );
  }
}

class _PrimaryPlatformInfo extends StatelessWidget {
  final AuthPlatform activePlatform;

  const _PrimaryPlatformInfo({required this.activePlatform});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = activePlatform == AuthPlatform.anilist
        ? 'AniList'
        : 'MyAnimeList';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, size: 20, color: colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Syncing to ',
                children: [
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' by default.'),
                ],
              ),
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
