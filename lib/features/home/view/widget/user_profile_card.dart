import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/auth/model/user.dart';
import 'package:shonenx/features/home/view/widget/header_base_card.dart'; // Import the base card
import 'package:shonenx/utils/greeting_methods.dart';

class UserProfileCard extends StatelessWidget {
  final AuthUser? user;

  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use the base card as the foundation
    return HeaderBaseCard(
      color: theme.colorScheme.surface, // A solid, clean background
      onTap: user != null ? () => context.push('/settings/profile') : () => context.push('/login'),
      child: Row(
        children: [
          _buildAvatar(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null ? getGreeting() : 'Welcome!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'Guest',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16.0);

    // Guest Avatar
    if (user == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: borderRadius,
        ),
        child: Icon(Iconsax.user, size: 24, color: theme.colorScheme.primary),
      );
    }
    
    // Logged-in User Avatar
    return Hero(
      tag: 'user-avatar',
      child: Material(
        type: MaterialType.transparency, // Avoid double shadows
        child: ClipRRect(
          borderRadius: borderRadius,
          child: CachedNetworkImage(
            imageUrl: user?.avatarUrl ?? '',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.person_outline, color: theme.colorScheme.onSurfaceVariant),
            ),
            errorWidget: (_, __, ___) => Container(
              color: theme.colorScheme.errorContainer,
              child: Icon(Icons.error_outline, color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }
}