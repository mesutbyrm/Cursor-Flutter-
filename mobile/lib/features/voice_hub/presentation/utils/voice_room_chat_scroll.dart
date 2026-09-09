import 'package:flutter/material.dart';

/// Ters (reverse) sohbet listesinde en altta (en yeni mesaj) mı?
bool voiceRoomChatIsAtLatest(
  ScrollController controller, {
  double threshold = 48,
}) {
  if (!controller.hasClients) return true;
  return controller.offset <= threshold;
}

/// Yeni mesaj geldiğinde bekleyen sayaç — yalnızca kullanıcı yukarı kaydırmışsa artar.
int voiceRoomChatPendingOnNewMessages({
  required int oldVisibleCount,
  required int newVisibleCount,
  required bool wasAtLatest,
}) {
  if (wasAtLatest || newVisibleCount <= oldVisibleCount) return 0;
  return newVisibleCount - oldVisibleCount;
}
