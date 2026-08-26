import 'package:flutter/widgets.dart';

/// Oyun odası 5 sn poll — arka planda istek atılmaz.
bool gameRoomPollAllowed(AppLifecycleState? state) {
  if (state == null) return true;
  return state == AppLifecycleState.resumed;
}
