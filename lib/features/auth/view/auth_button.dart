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
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16.0) : Radius.zero,
          bottom: isLast ? const Radius.circular(16.0) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => notifier.changePlatform(platform),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16.0) : Radius.zero,
            bottom: isLast ? const Radius.circular(16.0) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: isActive
                        ? Border.all(color: primaryColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      logoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_rounded,
                          color: primaryColor,
                          size: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

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
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 1),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isAuthenticated && user != null)
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connected as ${user.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),

                // Action
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  )
                else if (isAuthenticated)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'logout':
                          _showLogoutDialog(context, serviceName,
                              () => notifier.logout(platform));
                          break;
                        case 'set_active':
                          notifier.changePlatform(platform);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (!isActive)
                        PopupMenuItem(
                          value: 'set_active',
                          child: Row(
                            children: [
                              Icon(Icons.radio_button_checked,
                                  color: primaryColor, size: 18),
                              const SizedBox(width: 8),
                              const Text('Set as Active'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                color: theme.colorScheme.errorContainer,
                                size: 18),
                            const SizedBox(width: 8),
                            const Text('Disconnect'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(Icons.more_vert_rounded,
                          size: 18, color: theme.iconTheme.color),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => notifier.login(platform),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
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
