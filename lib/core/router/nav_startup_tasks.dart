import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_ui.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:shonenx/features/extensions/presentation/widgets/runtime_setup_sheet.dart';
import 'package:shonenx/features/extensions/providers/runtime_update_provider.dart';
import 'package:shonenx/features/updates/services/update_service.dart';
import 'package:shonenx/features/updates/ui/update_ui.dart';

Future<void> runNavStartupTasks(
  WidgetRef ref, {
  required bool Function() isMounted,
}) async {
  final config = await ref.read(remoteConfigStateProvider.future);
  if (config != null && !config.applicationEnabled) return;
  if (!isMounted()) return;

  final navContext = rootNavigatorKey.currentContext;
  if (navContext == null || !navContext.mounted) return;

  // 1. Check GitHub Release Updates
  try {
    final updatePrefs = ref.read(updatePrefsProvider);
    if (updatePrefs.autoCheckOnStartup) {
      final updateService = ref.read(updateServiceProvider);
      final release = await updateService.checkForUpdate();
      if (release != null && navContext.mounted) {
        await UpdateUI.showReleaseUpdateSheet(
          navContext,
          release: release,
          onDismiss: () => ref
              .read(updatePrefsProvider.notifier)
              .setLastDismissedReleaseId(release.id),
          onDownload: () => ref
              .read(updatePrefsProvider.notifier)
              .setLastSeenReleaseId(release.id),
        );
      }
    }
  } catch (_) {}

  if (!isMounted() || !navContext.mounted) return;

  // 1.5 Check Runtime Update
  try {
    final updateVersion = await ref.read(runtimeUpdateProvider.future);
    if (updateVersion != null && navContext.mounted) {
      await showRuntimeSetupSheet(navContext, ref);
    }
  } catch (_) {}

  if (!isMounted() || !navContext.mounted) return;

  // 2. Check Announcements
  final service = ref.read(remoteConfigServiceProvider);
  final announcement = service.getActiveAppAnnouncement();
  if (announcement != null) {
    await RemoteConfigUI.showAnnouncementSheet(
      navContext,
      announcement: announcement,
    );
    await service.markAnnouncementAsSeen(announcement.id);
  }
}
