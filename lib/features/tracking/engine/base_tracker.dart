import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';

abstract class BaseTracker implements TrackingService {
  late final ScopedLogger _log = AppLogger.scope(type.displayName);

  Future<T> executeApi<T>(
    String action,
    Future<T> Function() request, {
    T Function(Object e, StackTrace st)? fallback,
  }) async {
    final log = _log.child(action);

    log.d('START');

    try {
      final result = await request();

      String meta = '';
      if (result is Iterable) {
        meta = ' (size: ${result.length})';
      } else if (result is Map) {
        meta = ' (size: ${result.length})';
      } else if (result == null) {
        meta = ' (null)';
      }

      log.s('SUCCESS$meta');

      return result;
    } catch (e, st) {
      log.e('FAILED', e, st);

      if (fallback != null) {
        return fallback(e, st);
      }
      rethrow;
    }
  }
}
