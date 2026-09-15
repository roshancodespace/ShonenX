import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/settings/domain/models/sheet_physics_mode.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

export 'package:shonenx/features/settings/domain/models/sheet_physics_mode.dart';

class SheetPhysicsNotifier extends Notifier<SheetPhysicsMode> {
  static const _key = 'sheet_physics_mode';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  SheetPhysicsMode build() {
    final saved = _storage.getString(_key);
    return SheetPhysicsMode.fromJson(saved);
  }

  void setMode(SheetPhysicsMode mode) {
    if (state == mode) return;
    state = mode;
    _storage.setString(_key, mode.toJson());
  }

  void toggleMode() {
    final next = state == SheetPhysicsMode.hammer
        ? SheetPhysicsMode.slideUp
        : SheetPhysicsMode.hammer;
    setMode(next);
  }
}

final sheetPhysicsProvider =
    NotifierProvider<SheetPhysicsNotifier, SheetPhysicsMode>(
      SheetPhysicsNotifier.new,
    );
