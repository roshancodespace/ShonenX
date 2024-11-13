import 'package:flutter/material.dart';
import 'package:nekoflow/screens/main/settings/about/about_screen.dart';
import 'package:nekoflow/screens/settings/theme_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
          ListTile(
            tileColor: Colors.transparent,
            leading: Icon(Icons.color_lens, size: 35, color: Theme.of(context).iconTheme.color,),
            title: Text("Theme", style: TextStyle(fontSize: 20)),
            subtitle: Text("Change the app theme"),
            trailing: Icon(Icons.navigate_next, size: 35, color: Theme.of(context).iconTheme.color,),
            onTap: () => Navigator.push(
              context,
              ModalBottomSheetRoute(
                  builder: (context) => ThemeScreen(),
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  useSafeArea: true),
            ),
          ),
          ListTile(
            tileColor: Colors.transparent,
            leading: Icon(Icons.info, size: 35, color: Theme.of(context).iconTheme.color,),
            title: Text("About", style: TextStyle(fontSize: 20)),
            subtitle: Text("Information about the developer"),
            trailing: Icon(Icons.navigate_next, size: 35, color: Theme.of(context).iconTheme.color,),
            onTap: () => Navigator.push(
              context,
              ModalBottomSheetRoute(
                  builder: (context) => AboutScreen(),
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  useSafeArea: true),
            ),
          ),
        ],
      ),
    );
  }
}
