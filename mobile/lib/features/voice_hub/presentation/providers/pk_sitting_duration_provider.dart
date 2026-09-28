import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının oda içi oturma süresi (PK öncesi 2 dakika bekleme).
/// Oda değiştiğinde sıfırlanır.
class RoomSittingDurationNotifier extends StateNotifier<DateTime?> {
  RoomSittingDurationNotifier() : super(null);

  void markRoomEntry() {
    state = DateTime.now();
  }

  void reset() {
    state = null;
  }

  bool canAttackPk() {
    if (state == null) return false;
    final elapsed = DateTime.now().difference(state!);
    return elapsed.inSeconds >= 120;
  }

  Duration? getRemainingDuration() {
    if (state == null) return null;
    final elapsed = DateTime.now().difference(state!);
    if (elapsed.inSeconds >= 120) return Duration.zero;
    return Duration(seconds: 120 - elapsed.inSeconds);
  }
}

final roomSittingDurationProvider =
    StateNotifierProvider<RoomSittingDurationNotifier, DateTime?>((ref) {
  return RoomSittingDurationNotifier();
});
