import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/screens/main/settings/about/about_screen.dart';
import 'package:nekoflow/screens/main/settings/profile/profile_screen.dart';
import 'package:nekoflow/screens/main/settings/storage/storage_screen.dart';
import 'package:nekoflow/screens/settings/theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper method for creating list tiles
  Widget _buildListTile({
    required BuildContext context,
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      tileColor: Colors.transparent,
      leading: Icon(
        leadingIcon,
        size: 33,
        color: theme.colorScheme.secondary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 20),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        HugeIcons.strokeRoundedArrowRightDouble,
        color: theme.iconTheme.color,
        size: 30,
      ),
      onTap: () => Navigator.push(
        context,
        ModalBottomSheetRoute(
          builder: (context) => destination,
          isScrollControlled: true,
          isDismissible: true,
          enableDrag: true,
          useSafeArea: true,
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
        title: Text(
          "Settings",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: ListView(
        children: [
          _buildListTile(
            context: context,
            leadingIcon: HugeIcons.strokeRoundedCircleArrowDataTransferHorizontal,
            title: "Profile (SOON)",
            subtitle: "Information about you",
            destination: const ProfileScreen(),
          ),
          _buildListTile(
            context: context,
            leadingIcon: Icons.color_lens,
            title: "Theme",
            subtitle: "Change the app theme",
            destination: const ThemeScreen(),
          ),
          _buildListTile(
            context: context,
            leadingIcon: HugeIcons.strokeRoundedInformationCircle,
            title: "About",
            subtitle: "Information about the developer",
            destination: const AboutScreen(),
          ),
          _buildListTile(
            context: context,
            leadingIcon: HugeIcons.strokeRoundedCircleArrowDataTransferHorizontal,
            title: "Storage (SOON)",
            subtitle: "Export and import your data",
            destination: const StorageScreen(),
          ),
          
        ],
      ),
    );
  }
}
