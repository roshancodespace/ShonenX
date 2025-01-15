import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/screens/main/settings/about/about_screen.dart';
import 'package:nekoflow/screens/main/settings/theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper method for creating custom list tiles
  Widget _buildCustomTile({
    required BuildContext context,
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) =>
              SafeArea(maintainBottomViewPadding: true, child: destination),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 35,
                  color: theme.colorScheme.secondary,
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
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
    return SafeArea(
      maintainBottomViewPadding: true,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: 200,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
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
          children: [
            // _buildCustomTile(
            //   context: context,
            //   leadingIcon: HugeIcons.strokeRoundedProfile,
            //   title: "Profile (SOON)",
            //   subtitle: "Information about you",
            //   destination: const ProfileScreen(),
            // ),
            _buildCustomTile(
              context: context,
              leadingIcon: Icons.color_lens,
              title: "Theme",
              subtitle: "Change the app theme",
              destination: const ThemeScreen(
                title: 'Theme',
              ),
            ),
            _buildCustomTile(
              context: context,
              leadingIcon: HugeIcons.strokeRoundedInformationCircle,
              title: "About",
              subtitle: "Information about the developer",
              destination: const AboutScreen(
                title: 'About',
              ),
            ),
            // _buildCustomTile(
            //   context: context,
            //   leadingIcon: HugeIcons.strokeRoundedCircleArrowDataTransferHorizontal,
            //   title: "Storage (SOON)",
            //   subtitle: "Export and import your data",
            //   destination: const StorageScreen(),
            // ),
          ],
        ),
      ),
    );
  }
}
