import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'onboarding_complete';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, false);
    state = false;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});
