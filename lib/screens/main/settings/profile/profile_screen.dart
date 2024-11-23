import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/user_box.dart';
import 'package:nekoflow/data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserBox _userBox;
  UserModel _user = UserModel(name: null);

  @override
  void initState() {
    super.initState();
    _initializeUserBox();
  }

  Future<void> _initializeUserBox() async {
    _userBox = UserBox();
    await _userBox.init(); // Initialize the box
    _user = _userBox.getUser(); // Fetch user data

    // Update UI once data is loaded
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show a loading spinner while user data is being fetched
    if (_user.name == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.navigate_before,
            size: 35,
          ),
        ),
        title: Text(
          "Profile",
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
        ),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    _user.name?.split('')[0] ?? '',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user.name ?? "Unknown User",
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(context, 'Watched', 0), // Placeholder values
                    _buildVerticalDivider(),
                    _buildStat(context, 'Watchlist', 0),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          _buildMenuItem(
            context,
            Icons.bookmark,
            'My Watchlist',
            'Track your upcoming shows',
          ),
          _buildMenuItem(
            context,
            Icons.history,
            'Watch History',
            'Shows you have completed',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, int value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to respective screens
      },
    );
  }
}
