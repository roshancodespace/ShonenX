enum AppAction {
  navHome,
  navSearch,
  navLibrary,
  navDownloads,
  actionProfile,
  actionSettings,
  actionCalendar,
  actionDiscover,
}

enum AppRegion { bottomNav, sideRail, topHeader, floatingDock }

enum SurfaceAppearance {
  classic,
  minimal,
  material,
  prominent,
  frosted,
  docked,
}

class SurfaceConfig {
  final List<AppAction> actions;
  final SurfaceAppearance appearance;

  const SurfaceConfig({required this.actions, required this.appearance});

  Map<String, dynamic> toMap() {
    return {
      'actions': actions.map((x) => x.name).toList(),
      'appearance': appearance.name,
    };
  }

  factory SurfaceConfig.fromMap(Map<String, dynamic> map) {
    return SurfaceConfig(
      actions:
          (map['actions'] as List?)
              ?.map(
                (x) => AppAction.values.firstWhere(
                  (e) => e.name == x,
                  orElse: () => AppAction.navHome,
                ),
              )
              .toList() ??
          [],
      appearance: SurfaceAppearance.values.firstWhere(
        (e) => e.name == map['appearance'],
        orElse: () => SurfaceAppearance.classic,
      ),
    );
  }
}

class AppLayoutPreset {
  final Map<AppRegion, SurfaceConfig> regions;

  const AppLayoutPreset({required this.regions});

  Map<String, dynamic> toMap() {
    return {
      'regions': regions.map((key, value) => MapEntry(key.name, value.toMap())),
    };
  }

  factory AppLayoutPreset.fromMap(Map<String, dynamic> map) {
    final regionsMap = map['regions'] as Map<String, dynamic>? ?? {};
    final regions = <AppRegion, SurfaceConfig>{};
    for (final entry in regionsMap.entries) {
      final region = AppRegion.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => AppRegion.bottomNav,
      );
      regions[region] = SurfaceConfig.fromMap(entry.value);
    }
    return AppLayoutPreset(regions: regions);
  }
}

class ResponsiveLayoutPreset {
  final String id;
  final String name;
  final AppLayoutPreset mobile;
  final AppLayoutPreset desktop;

  const ResponsiveLayoutPreset({
    required this.id,
    required this.name,
    required this.mobile,
    required this.desktop,
  });
}
