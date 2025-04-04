import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/router/router.dart';
import 'package:shonenx/theme/app_theme.dart';
import 'package:shonenx/app_initializer.dart';
import 'package:window_manager/window_manager.dart';

// Define intent classes
class ToggleFullscreenIntent extends Intent {
  const ToggleFullscreenIntent();
}

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
  bool _isFullscreen = false; // Track fullscreen state

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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      windowManager.setFullScreen(true);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      windowManager.setFullScreen(false);
    }
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

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.f11): ToggleFullscreenIntent(),
      },
      child: Actions(
        actions: {
          ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
            onInvoke: (intent) => _toggleFullscreen(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: ValueListenableBuilder<Box>(
            valueListenable: _settingsBox!.settingsBoxListenable,
            builder: (context, box, child) {
              final appearanceSettings =
                  _settingsBox?.getThemeSettings() ?? ThemeSettingsModel();
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
          ),
        ),
      ),
    );
  }
}
