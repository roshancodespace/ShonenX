import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_2, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Text(
                'Customize Your Experience',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingsGroup(
                context,
                title: 'Account',
                items: [
                  SettingsItem(
                    icon: Iconsax.user,
                    title: 'Profile Settings',
                    description: 'AniList integration, account preferences',
                    onTap: () => context.push('/settings/profile'),
                  ),
                ],
              ),
              _buildSettingsGroup(
                context,
                title: 'Content & Playback',
                items: [
                  SettingsItem(
                    icon: Iconsax.video_play,
                    title: 'Video Player',
                    description: 'Playback settings, subtitles configuration',
                    onTap: () => context.push('/settings/player'),
                  ),
                  SettingsItem(
                    icon: Iconsax.play,
                    title: 'Anime Sources',
                    description: 'Manage content providers',
                    onTap: () => context.push('/settings/providers'),
                  ),
                ],
              ),
              _buildSettingsGroup(
                context,
                title: 'Appearance',
                items: [
                  SettingsItem(
                    icon: Iconsax.brush_2,
                    title: 'Theme Settings',
                    description: 'Customize app colors and appearance',
                    onTap: () => context.push('/settings/theme'),
                  ),
                  SettingsItem(
                    icon: Iconsax.brush_2,
                    title: 'UI Settings',
                    description: 'Customize the interface and layout',
                    onTap: () => context.push('/settings/ui'),
                  ),
                ],
              ),
              _buildSettingsGroup(
                context,
                title: 'Support',
                items: [
                  SettingsItem(
                    icon: Iconsax.message_question,
                    title: 'Help Center',
                    description: 'FAQs and support resources',
                    onTap: () => context.push('/settings/support'),
                  ),
                  SettingsItem(
                    icon: Iconsax.info_circle,
                    title: 'About',
                    description: 'App information and licenses',
                    onTap: () => context.push('/settings/about'),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<SettingsItem> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
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
            elevation: 3,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            surfaceTintColor: Colors.transparent,
            color: colorScheme.surface,
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
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
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

class SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
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
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.disabled
                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                      : colorScheme.primary,
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
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
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
                size: 20,
                color: widget.disabled
                    ? colorScheme.onSurface.withValues(alpha: 0.2)
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
