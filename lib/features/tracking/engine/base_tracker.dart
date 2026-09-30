import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

abstract class BaseTracker implements TrackingService {
  late final ScopedLogger _log = AppLogger.scope(type.displayName);

  Future<T> executeApi<T>(
    String action,
    Future<T> Function() request, {
    T Function(Object e, StackTrace st)? fallback,
  }) async {
    final log = _log.child(action);
    
    try {
      final result = await request();

      String meta = '';
      if (result is Iterable) {
        meta = ' (size: ${result.length})';
      } else if (result is Map) {
        meta = ' (size: ${result.length})';
      } else if (result is PaginatedResult) {
        meta = ' (size: ${result.items.length})';
      } else if (result == null) {
        meta = ' (null)';
      }

      log.s('Success$meta');

      return result;
    } on TrackerItemNotFoundException catch (e, st) {
      log.i('Not Found: ${e.message}');
      if (fallback != null) {
        return fallback(e, st);
      }
      rethrow;
    } catch (e, st) {
      log.e('Failed', e, st);

      if (fallback != null) {
        return fallback(e, st);
      }
      rethrow;
    }
  }
}

class TrackerItemNotFoundException implements Exception {
  final String message;
  const TrackerItemNotFoundException([
    this.message = 'Item not found in tracker.',
  ]);

  @override
  String toString() => message;
}
