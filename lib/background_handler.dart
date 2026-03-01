import 'package:shonenx/core/tasks/news_task.dart';
import 'package:shonenx/core/tasks/sync_tracking_task.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "sync_tracking_task") {
      return await SyncTrackingTask.performSync(inputData);
    }
    return await NewsBackgroundTask.performUpdate();
  });
}
