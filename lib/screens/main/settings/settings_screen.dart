import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/screens/main/settings/about/about_screen.dart';
import 'package:nekoflow/screens/main/settings/theme_screen_v2.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper method for creating custom list tiles
  Widget _buildCustomTile({
    required BuildContext context,
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required String destination,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push(destination),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 35,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: ValueKey(title),
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  HugeIcons.strokeRoundedArrowRightDouble,
                  color: theme.iconTheme.color,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 200,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 30,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          "Settings",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          _buildCustomTile(
            context: context,
            leadingIcon: Icons.color_lens,
            title: "Theme",
            subtitle: "Customize your app's appearance",
            destination: '/settings/Theme',
          ),
          _buildCustomTile(
            context: context,
            leadingIcon: HugeIcons.strokeRoundedInformationCircle,
            title: "About",
            subtitle: "Learn more about the developer",
            destination: '/settings/About',
          ),
        ],
      ),
    );
  }
}
