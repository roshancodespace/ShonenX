import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/boxes/settings_box.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';
import 'package:nekoflow/data/models/user_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/onboarding/onboarding_screen.dart';
import 'package:nekoflow/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(ThemeModelAdapter());
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
  late String _themeMode;
  late FlexScheme _flexScheme;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox.init();
    _themeMode = _settingsBox.getTheme()?.themeMode ??
        'light'; // Default to 'light' if null
    _flexScheme = _settingsBox.getTheme()?.flexScheme ??
        FlexScheme.red; // Default to FlexScheme.blue if null
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SettingsModel>>(
      valueListenable: _settingsBox.listenable(),
      builder: (context, box, child) {
        final theme = _settingsBox.getTheme()?.themeMode;
        _themeMode = theme == 'dark'
            ? 'dark'
            : theme == 'light'
                ? 'light'
                : (MediaQuery.of(context).platformBrightness == Brightness.dark
                    ? 'dark'
                    : 'light');

        _flexScheme = _settingsBox.getTheme()?.flexScheme ?? FlexScheme.red;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _themeMode == 'dark'
              ? FlexThemeData.dark(
                  scheme: _flexScheme,
                  textTheme: GoogleFonts.montserratTextTheme()
                )
              : FlexThemeData.light(
                  scheme: _flexScheme,
                  textTheme: GoogleFonts.montserratTextTheme()
                ),
          home: Scaffold(
            extendBody: true,
            appBar: AppBar(toolbarHeight: 0),
            body: const OnboardingScreen(),
          ),
        );
      },
    );
  }
}
