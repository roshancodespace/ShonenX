import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/router/router.dart';
import 'package:shonenx/theme/app_theme.dart';
import 'package:shonenx/helpers/app_initializer.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBoxInitialized = false;
  late SettingsBox? _settingsBox;

  @override
  void initState() {
    super.initState();
    _initializeSettingsBox();
  }

  Future<void> _initializeSettingsBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    setState(() {
      _isBoxInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<Box>(
      valueListenable: _settingsBox!.settingsBoxListenable,
      builder: (context, box, child) {
        final appearanceSettings =
            _settingsBox?.getAppearanceSettings() ?? ThemeSettingsModel();
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(appearanceSettings),
          darkTheme: AppTheme.dark(appearanceSettings),
          themeMode: appearanceSettings.themeMode == 'light'
              ? ThemeMode.light
              : appearanceSettings.themeMode == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
