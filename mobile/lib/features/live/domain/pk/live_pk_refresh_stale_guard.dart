import 'live_pk_broadcast_stage.dart';
import 'pk_status_helper.dart';

/// Boş/hatalı `refresh` yanıtında mevcut PK battle haritasını korur (single-live düşüşünü önler).
bool shouldRetainPkBattleOnEmptyRefresh({
  required Map<String, dynamic>? battle,
  required String? status,
  required DateTime? lastAuthorityAt,
  Duration staleTtl = const Duration(seconds: 90),
  DateTime? now,
}) {
  if (battle == null || battle.isEmpty) return false;
  final clock = now ?? DateTime.now();
  if (isPkInvitePendingStatus(status)) return true;
  if (isLivePkBroadcastStage(battle, status)) return true;
  if (isLivePkActiveStatus(status) || isLivePkStartingStatus(status)) {
    if (lastAuthorityAt != null &&
        clock.difference(lastAuthorityAt) < staleTtl) {
      return true;
    }
  }
  return false;
}
