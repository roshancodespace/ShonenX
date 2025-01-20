import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/adapters/flex_scheme_adapter.dart';
import 'package:nekoflow/data/boxes/settings_box.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';
import 'package:nekoflow/data/models/user_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/routes/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(ThemeModelAdapter());
  Hive.registerAdapter(FlexSchemeAdapter());
  Hive.registerAdapter(WatchlistModelAdapter());
  Hive.registerAdapter(RecentlyWatchedItemAdapter());
  Hive.registerAdapter(ContinueWatchingItemAdapter());
  Hive.registerAdapter(AnimeItemAdapter());
  Hive.registerAdapter(UserModelAdapter());

  // Open boxes concurrently
  await Future.wait([
    Hive.openBox<UserModel>("user"),
    Hive.openBox<WatchlistModel>("watchlist"),
    Hive.openBox<SettingsModel>("settings"),
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final SettingsBox _settingsBox;
  late ThemeModel _themeModel;
  late FlexScheme _flexScheme;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeBox();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _initializeBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox.init();
    _updateThemeSettings();
  }

  void _updateThemeSettings() {
    _themeModel = _settingsBox.getTheme()!;
    _flexScheme = _themeModel.flexScheme;
  }

  ThemeData _buildThemeData(bool isDark) {
    return isDark
        ? FlexThemeData.dark(
            scheme: _flexScheme,
            blendLevel: 18,
            darkIsTrueBlack: _themeModel.trueBlack,
            swapColors: _themeModel.swapColors,
            subThemesData: FlexSubThemesData(
              interactionEffects: true,
              cardRadius: _themeModel.cardRadius,
            ),
            textTheme: GoogleFonts.montserratTextTheme(),
          )
        : FlexThemeData.light(
            scheme: _flexScheme,
            blendLevel: 15,
            swapColors: _themeModel.swapColors,
            subThemesData: FlexSubThemesData(
              interactionEffects: true,
              cardRadius: _themeModel.cardRadius,
            ),
            textTheme: GoogleFonts.montserratTextTheme(),
          );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SettingsModel>>(
      valueListenable: _settingsBox.listenable(),
      builder: (context, box, child) {
        _updateThemeSettings();
        bool isDark = _themeModel.themeMode == 'dark' ||
            (_themeModel.themeMode == 'system' &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: _buildThemeData(isDark),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
