import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/onboarding/onboarding_model.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/theme/theme_manager.dart';
import 'package:nekoflow/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(WatchlistModelAdapter());
  Hive.registerAdapter(RecentlyWatchedItemAdapter());
  Hive.registerAdapter(ContinueWatchingItemAdapter());
  Hive.registerAdapter(AnimeItemAdapter());
  Hive.registerAdapter(OnboardingModelAdapter());

  await Hive.openBox<SettingsModel>('user_settings');
  await Hive.openBox<WatchlistModel>('user_watchlist');
  await Hive.openBox<OnboardingModel>('onboarding');

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Box<SettingsModel> settingsBox;
  ThemeType _theme = ThemeType.dark;

  Future<void> _loadTheme() async {
    final userTheme = settingsBox.get('theme') ??
        SettingsModel(theme: _theme.toString().split('.').last.toLowerCase());
    String? themeName = userTheme.theme;

    setState(() {
      _theme = ThemeManager.getThemeType(
              themeName ?? _theme.toString().split('.').last.toLowerCase()) ??
          ThemeType.dark;
    });
  }

  @override
  void initState() {
    super.initState();
    _theme = ThemeType.light;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    settingsBox = Hive.box<SettingsModel>('user_settings');
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['theme']),
      builder: (context, Box<SettingsModel> box, child) {
        // Update theme when 'theme' value changes in settingsBox
        _theme = ThemeManager.getThemeType(
                box.get('theme')?.theme ?? _theme.toString()) ??
            ThemeType.light;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeManager.getTheme(_theme),
          home: Scaffold(
            extendBody: true,
            appBar: AppBar(toolbarHeight: 0),
            body: OnboardingScreen(),
          ),
        );
      },
    );
  }
}
