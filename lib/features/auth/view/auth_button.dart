import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import '../view_model/auth_notifier.dart';

class AccountAuthenticationSection extends ConsumerWidget {
  const AccountAuthenticationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildServiceTile(
                context: context,
                ref: ref,
                state: state,
                platform: AuthPlatform.anilist,
                serviceName: 'AniList',
                description: 'Track anime and manga progress',
                logoUrl:
                    'https://anilist.co/img/icons/android-chrome-512x512.png',
                primaryColor: const Color(0xFF02A9FF),
                isFirst: true,
              ),
              Divider(
                height: 1,
                color: theme.dividerColor,
                indent: 20,
                endIndent: 20,
              ),
              _buildServiceTile(
                context: context,
                ref: ref,
                state: state,
                platform: AuthPlatform.mal,
                serviceName: 'MyAnimeList',
                description: 'Sync with your MAL account',
                logoUrl:
                    'https://cdn.myanimelist.net/img/sp/icon/apple-touch-icon-256.png',
                primaryColor: const Color(0xFF2E51A2),
                isLast: true,
              ),
            ],
          ),
        ),
        if (state.isAniListAuthenticated || state.isMalAuthenticated) ...[
          const SizedBox(height: 16),
          _buildActivePlatformIndicator(context, state),
        ],
      ],
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required WidgetRef ref,
    required AuthState state,
    required AuthPlatform platform,
    required String serviceName,
    required String description,
    required String logoUrl,
    required Color primaryColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final notifier = ref.read(authProvider.notifier);

    final isAuthenticated = state.isAuthenticatedFor(platform);
    final isLoading = state.isLoadingFor(platform);
    final user = state.userFor(platform);
    final isActive = state.activePlatform == platform;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24.0) : Radius.zero,
          bottom: isLast ? const Radius.circular(24.0) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => notifier.changePlatform(platform),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(24.0) : Radius.zero,
            bottom: isLast ? const Radius.circular(24.0) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                    border: isActive
                        ? Border.all(color: primaryColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      logoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_rounded,
                          color: primaryColor,
                          size: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            serviceName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isAuthenticated && user != null)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connected as ${user.name}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  )
                else if (isAuthenticated)
                  IconButton.filledTonal(
                      onPressed: () {
                        // Simplify popup to just logout for now, or keep existing logic
                        _showLogoutDialog(context, serviceName,
                            () => notifier.logout(platform));
                      },
                      icon: Icon(Icons.logout_rounded,
                          color: theme.colorScheme.error),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.error.withOpacity(0.1),
                      ))
                else
                  ElevatedButton(
                    onPressed: () => notifier.login(platform),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: const Text('Connect',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePlatformIndicator(BuildContext context, AuthState state) {
    final theme = Theme.of(context);
    final activePlatformName = switch (state.activePlatform) {
      AuthPlatform.anilist => 'AniList',
      AuthPlatform.mal => 'MyAnimeList',
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Primary platform: $activePlatformName will be used for default operations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context, String serviceName, VoidCallback onConfirm) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded,
                color: colorScheme.errorContainer, size: 24),
            const SizedBox(width: 12),
            const Text('Disconnect Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to disconnect from $serviceName? You\'ll need to reconnect to sync your data.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
