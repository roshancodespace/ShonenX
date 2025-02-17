import 'dart:developer';
import 'dart:io';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/data/hive/adapters/flex_scheme_adapter.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/continue_watching_model.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/router/router.dart';
import 'package:window_manager/window_manager.dart';

bool windowManagerInitialized = false;

class AppInitializer {
  static Future<void> initialize() async {
    log("🚀 Main() Called");

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      log("⚠️ Running in test mode, exiting main.");
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    log("✅ Flutter bindings initialized.");

    await _initializeMediaKit();
    await _initializeHive();
    await _initializeWindowManager();
  }

  static Future<void> _initializeMediaKit() async {
    MediaKit.ensureInitialized();
    log("✅ MediaKit initialized.");
  }

  static Future<void> _initializeHive() async {
    String customPath;

    if (Platform.isWindows) {
      // Custom folder inside the user's Documents directory (or any path you prefer)
      customPath = '${Directory.current.path}\\hive_data'; // Or any other path
    } else {
      // Default for other platforms
      customPath = (await getApplicationDocumentsDirectory()).path;
    }

    Hive.init(customPath);
    log("✅ Hive initialized at: $customPath");

    // Register your adapters as usual
    Hive.registerAdapter(SettingsModelAdapter());
    Hive.registerAdapter(ProviderSettingsModelAdapter());
    Hive.registerAdapter(AppearanceSettingsModelAdapter());
    Hive.registerAdapter(PlayerSettingsModelAdapter());
    Hive.registerAdapter(ContinueWatchingEntryAdapter());
    Hive.registerAdapter(FlexSchemeAdapter());

    log("✅ Hive adapters registered.");
  }

  static Future<void> _initializeWindowManager() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      try {
        if (!windowManagerInitialized) {
          await windowManager.ensureInitialized();
          windowManagerInitialized = true;

          WindowOptions windowOptions = WindowOptions(
            center: true,
            backgroundColor: Colors.black,
            skipTaskbar: false,
            title: "ShonenX Beta",
          );

          await windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();
          });

          log("✅ Window Manager Initialized");
        }
      } catch (e) {
        log("❌ Window Manager Initialization Error: $e");
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      log("✅ System UI Mode set to edge-to-edge.");
    }
  }
}

void main(List<String> args) async {
  await AppInitializer.initialize();
  log("🏃 Running App");
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
      return SizedBox.shrink();
    }
    return ValueListenableBuilder<Box>(
        valueListenable: _settingsBox!.settingsBoxListenable,
        builder: (context, box, child) {
          final appearanceSettings =
              _settingsBox?.getSettings()?.appearanceSettings;
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: FlexThemeData.light(
              scheme: appearanceSettings?.colorScheme,
              appBarStyle: FlexAppBarStyle.primary,
              appBarElevation: 4.0,
              bottomAppBarElevation: 8.0,
              tabBarStyle: FlexTabBarStyle.forAppBar,
              textTheme: GoogleFonts.montserratTextTheme(),
              subThemesData: const FlexSubThemesData(
                useM2StyleDividerInM3: true,
                adaptiveElevationShadowsBack: FlexAdaptive.all(),
                adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
                defaultRadius: 4.0,
                elevatedButtonSchemeColor: SchemeColor.onPrimary,
                elevatedButtonSecondarySchemeColor: SchemeColor.primary,
                inputDecoratorSchemeColor: SchemeColor.onSurface,
                inputDecoratorIsFilled: true,
                inputDecoratorBackgroundAlpha: 13,
                inputDecoratorBorderSchemeColor: SchemeColor.primary,
                inputDecoratorBorderType: FlexInputBorderType.outline,
                listTileContentPadding:
                    EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                listTileMinVerticalPadding: 4.0,
                fabUseShape: true,
                fabAlwaysCircular: true,
                fabSchemeColor: SchemeColor.secondary,
                chipSchemeColor: SchemeColor.primary,
                chipRadius: 20.0,
                popupMenuElevation: 8.0,
                alignedDropdown: true,
                tooltipRadius: 4,
                dialogElevation: 24.0,
                datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
                snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
                appBarScrolledUnderElevation: 4.0,
                tabBarIndicatorSize: TabBarIndicatorSize.tab,
                tabBarIndicatorWeight: 2,
                tabBarIndicatorTopRadius: 0,
                tabBarDividerColor: Color(0x00000000),
                drawerElevation: 16.0,
                drawerWidth: 304.0,
                bottomSheetElevation: 10.0,
                bottomSheetModalElevation: 20.0,
                bottomNavigationBarSelectedLabelSchemeColor:
                    SchemeColor.primary,
                bottomNavigationBarMutedUnselectedLabel: true,
                bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
                bottomNavigationBarMutedUnselectedIcon: true,
                bottomNavigationBarElevation: 8.0,
                menuElevation: 8.0,
                menuBarRadius: 0.0,
                menuBarElevation: 1.0,
                navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
                navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
                navigationBarMutedUnselectedLabel: true,
                navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
                navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
                navigationBarMutedUnselectedIcon: true,
                navigationBarIndicatorSchemeColor: SchemeColor.secondary,
                navigationBarBackgroundSchemeColor:
                    SchemeColor.surfaceContainer,
                navigationBarElevation: 0.0,
                navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
                navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
                navigationRailMutedUnselectedLabel: true,
                navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
                navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
                navigationRailMutedUnselectedIcon: true,
                navigationRailUseIndicator: true,
                navigationRailIndicatorSchemeColor: SchemeColor.secondary,
                navigationRailLabelType: NavigationRailLabelType.all,
              ),
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
            ),
            darkTheme: FlexThemeData.dark(
              scheme: appearanceSettings?.colorScheme,
              appBarStyle: FlexAppBarStyle.material,
              appBarElevation: 4.0,
              darkIsTrueBlack: appearanceSettings?.amoled ?? false,
              blendLevel: 15,
              bottomAppBarElevation: 8.0,
              tabBarStyle: FlexTabBarStyle.forAppBar,
              textTheme: GoogleFonts.montserratTextTheme(),
              subThemesData: const FlexSubThemesData(
                useM2StyleDividerInM3: true,
                adaptiveElevationShadowsBack: FlexAdaptive.all(),
                adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
                defaultRadius: 4.0,
                elevatedButtonSchemeColor: SchemeColor.onPrimary,
                elevatedButtonSecondarySchemeColor: SchemeColor.primary,
                inputDecoratorSchemeColor: SchemeColor.onSurface,
                inputDecoratorIsFilled: true,
                inputDecoratorBackgroundAlpha: 20,
                inputDecoratorBorderSchemeColor: SchemeColor.primary,
                inputDecoratorBorderType: FlexInputBorderType.outline,
                listTileContentPadding:
                    EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                listTileMinVerticalPadding: 4.0,
                fabUseShape: true,
                fabAlwaysCircular: true,
                fabSchemeColor: SchemeColor.secondary,
                chipSchemeColor: SchemeColor.primary,
                chipRadius: 20.0,
                popupMenuElevation: 8.0,
                alignedDropdown: true,
                tooltipRadius: 4,
                dialogElevation: 24.0,
                datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
                snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
                appBarScrolledUnderElevation: 4.0,
                tabBarIndicatorSize: TabBarIndicatorSize.tab,
                tabBarIndicatorWeight: 2,
                tabBarIndicatorTopRadius: 0,
                tabBarDividerColor: Color(0x00000000),
                drawerElevation: 16.0,
                drawerWidth: 304.0,
                bottomSheetElevation: 10.0,
                bottomSheetModalElevation: 20.0,
                bottomNavigationBarSelectedLabelSchemeColor:
                    SchemeColor.primary,
                bottomNavigationBarMutedUnselectedLabel: true,
                bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
                bottomNavigationBarMutedUnselectedIcon: true,
                bottomNavigationBarElevation: 8.0,
                menuElevation: 8.0,
                menuBarRadius: 0.0,
                menuBarElevation: 1.0,
                navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
                navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
                navigationBarMutedUnselectedLabel: true,
                navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
                navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
                navigationBarMutedUnselectedIcon: true,
                navigationBarIndicatorSchemeColor: SchemeColor.secondary,
                navigationBarBackgroundSchemeColor:
                    SchemeColor.surfaceContainer,
                navigationBarElevation: 0.0,
                navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
                navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
                navigationRailMutedUnselectedLabel: true,
                navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
                navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
                navigationRailMutedUnselectedIcon: true,
                navigationRailUseIndicator: true,
                navigationRailIndicatorSchemeColor: SchemeColor.secondary,
                navigationRailLabelType: NavigationRailLabelType.all,
              ),
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
            ),
            themeMode: appearanceSettings?.themeMode == 'light'
                ? ThemeMode.light
                : appearanceSettings?.themeMode == 'dark'
                    ? ThemeMode.dark
                    : ThemeMode.system,
            // theme: ThemeData(
            //   brightness: appearanceState?.themeMode == 'light'
            //       ? Brightness.light
            //       : Brightness.dark,
            //   textTheme: GoogleFonts.montserratTextTheme(
            //       appearanceState?.themeMode == 'light'
            //           ? ThemeData.light().textTheme
            //           : ThemeData.dark().textTheme),
            //   iconTheme: const IconThemeData(color: Colors.white),
            //   colorScheme: ColorScheme.fromSeed(
            //     seedColor: Colors.lime,
            //     brightness: appearanceState?.themeMode == 'light'
            //         ? Brightness.light
            //         : Brightness.dark,
            //   ),
            // ),
            routerConfig: router,
          );
        });
  }
}
