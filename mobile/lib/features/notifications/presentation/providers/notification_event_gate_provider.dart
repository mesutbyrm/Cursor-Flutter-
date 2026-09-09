import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/notification_event_gate.dart';

final notificationEventGateProvider = Provider<NotificationEventGate>((ref) {
  final gate = NotificationEventGate();
  gate.markSessionStart();
  ref.onDispose(gate.markSessionStart);
  return gate;
});
