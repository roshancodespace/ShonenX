import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/auth/view/auth_button.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
            onPressed: () => context.pop(), icon: Icon(Iconsax.arrow_left_2)),
        title: const Text('Account Settings'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AniList Card
            AniListLoginButton(),

            const SizedBox(height: 32),

            // Additional Settings Section
            // const Text(
            //   'Sync Settings',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 16),

            // _buildSyncOption(
            //   title: 'Auto Sync',
            //   subtitle: 'Automatically sync progress between accounts',
            //   value: true,
            //   onChanged: (value) {
            //     // Handle auto sync toggle
            //   },
            // ),

            // _buildSyncOption(
            //   title: 'Sync on Wi-Fi only',
            //   subtitle: 'Only sync when connected to Wi-Fi',
            //   value: false,
            //   onChanged: (value) {
            //     // Handle wifi sync toggle
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
