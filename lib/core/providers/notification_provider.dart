import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/notification_service.dart';

typedef NotificationConfig = ({
  String type,
  String refId,
  String variant,
  String title,
  String body,
  DateTime scheduleTime,
});

class NotifState {
  final bool isLoading;
  final bool isScheduled;

  const NotifState({this.isLoading = false, this.isScheduled = false});

  NotifState copyWith({bool? isLoading, bool? isScheduled}) => NotifState(
    isLoading: isLoading ?? this.isLoading,
    isScheduled: isScheduled ?? this.isScheduled,
  );
}

class NotifNotifier extends Notifier<NotifState> {
  late final NotificationService _service;
  late final int _id;

  final NotificationConfig arg;

  NotifNotifier(this.arg);

  @override
  NotifState build() {
    _service = NotificationService.instance;
    _id = NotificationService.generateId(arg.type, arg.refId, arg.variant);

    _init();
    return const NotifState(isLoading: true);
  }

  Future<void> _init() async {
    final scheduled = await _service.isScheduled(_id);
    state = NotifState(isScheduled: scheduled, isLoading: false);
  }

  Future<void> toggle() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      if (state.isScheduled) {
        await _service.cancel(_id);
        state = const NotifState(isScheduled: false, isLoading: false);
      } else {
        final ok = await _service.schedule(
          id: _id,
          title: arg.title,
          body: arg.body,
          scheduleTime: arg.scheduleTime,
        );
        state = NotifState(isScheduled: ok, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final notificationToggleProvider = NotifierProvider.autoDispose
    .family<NotifNotifier, NotifState, NotificationConfig>(NotifNotifier.new);
