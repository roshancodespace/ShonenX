import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/boxes/settings_box.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';
import 'package:nekoflow/data/models/user_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/theme/theme_manager.dart';
import 'package:nekoflow/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(WatchlistModelAdapter());
  Hive.registerAdapter(RecentlyWatchedItemAdapter());
  Hive.registerAdapter(ContinueWatchingItemAdapter());
  Hive.registerAdapter(AnimeItemAdapter());
  Hive.registerAdapter(UserModelAdapter());

// Await all boxes to be opened
  await Future.wait([
    Hive.openBox<UserModel>("user"),
    Hive.openBox<WatchlistModel>("watchlist"),
    Hive.openBox<SettingsModel>("settings"),
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late SettingsBox _settingsBox;
  ThemeType _theme = ThemeType.dark;

  Future<void> _loadTheme() async {
    final userTheme = _settingsBox.getTheme();
    debugPrint("MAIN: $userTheme");
    setState(() {
      _theme = ThemeManager.getThemeType(userTheme!) ?? ThemeType.dark;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeBox();
    _loadTheme();
  }

  Future<void> _initializeBox() async {
    _settingsBox = SettingsBox(); // Initialize SettingsBox
    await _settingsBox.init(); // Open the Settings box
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(),
      builder: (context, Box<SettingsModel> box, child) {
        _theme = ThemeManager.getThemeType(_settingsBox.getTheme() ?? 'dark') ??
            _theme;
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
