import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer openContainer() {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<UiPrefState> reopenAfterSave(
    ProviderContainer container,
    String expectedFragment,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(prefs.getString('ui_preferences'), contains(expectedFragment));
    container.dispose();
    return openContainer().read(uiPrefsProvider);
  }

  test('card style selection persists and restores', () async {
    final container = openContainer();
    container.read(uiPrefsProvider.notifier).updateCardStyle(MediaCardStyle.neon);

    final restored = await reopenAfterSave(container, '"cardStyle":"neon"');
    expect(restored.cardStyle, MediaCardStyle.neon);
  });

  test('continue watching style selection persists and restores', () async {
    final container = openContainer();
    container
        .read(uiPrefsProvider.notifier)
        .updateContinueWatchingStyle(MediaCardStyle.expressive);

    final restored = await reopenAfterSave(
      container,
      '"continueWatchingStyle":"expressive"',
    );
    expect(restored.continueWatchingStyle, MediaCardStyle.expressive);
  });

  test('continue reading style selection persists and restores', () async {
    final container = openContainer();
    container
        .read(uiPrefsProvider.notifier)
        .updateContinueReadingStyle(MediaCardStyle.editorial);

    final restored = await reopenAfterSave(
      container,
      '"continueReadingStyle":"editorial"',
    );
    expect(restored.continueReadingStyle, MediaCardStyle.editorial);
  });

  test('nav bar style selection persists and restores', () async {
    final container = openContainer();
    container.read(uiPrefsProvider.notifier).updateNavBarStyle(NavBarStyle.docked);

    final restored = await reopenAfterSave(container, '"navBarStyle":"docked"');
    expect(restored.navBarStyle, NavBarStyle.docked);
  });

  test('home header style selection persists and restores', () async {
    final container = openContainer();
    container
        .read(uiPrefsProvider.notifier)
        .updateHomeHeaderStyle(HomeHeaderStyle.prominent);

    final restored = await reopenAfterSave(
      container,
      '"homeHeaderStyle":"prominent"',
    );
    expect(restored.homeHeaderStyle, HomeHeaderStyle.prominent);
  });

  test('episode view mode selection persists and restores', () async {
    final container = openContainer();
    container
        .read(uiPrefsProvider.notifier)
        .updateEpisodeViewMode(EpisodeViewMode.grid);

    final restored = await reopenAfterSave(container, '"episodeViewMode":"grid"');
    expect(restored.episodeViewMode, EpisodeViewMode.grid);
  });

  test('card wide-mode toggle persists and restores', () async {
    final container = openContainer();
    final notifier = container.read(uiPrefsProvider.notifier);
    notifier.toggleMediaCardWide(MediaCardStyle.neon.name);
    expect(
      container.read(uiPrefsProvider).isMediaCardWide(MediaCardStyle.neon.name),
      isTrue,
    );

    final restored = await reopenAfterSave(container, '"media_neon":true');
    expect(restored.isMediaCardWide(MediaCardStyle.neon.name), isTrue);
  });
}
