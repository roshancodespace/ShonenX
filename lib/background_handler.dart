
import 'package:shonenx/core/tasks/news_task.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await NewsBackgroundTask.performUpdate();
  });
}
