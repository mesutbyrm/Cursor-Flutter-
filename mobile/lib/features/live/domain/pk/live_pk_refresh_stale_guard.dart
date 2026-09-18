import 'live_pk_broadcast_stage.dart';
import 'pk_status_helper.dart';

/// `refresh` sırasındaki bir hatanın "battle gerçekten yok" anlamına gelip
/// gelmediğini söyler.
///
/// Yalnızca sunucu bunu açıkça bildirdiğinde (404/410) battle silinebilir.
/// Ağ kopması, zaman aşımı ve 5xx bir **bilgi yokluğudur** — "maç bitti"
/// bilgisi değil — ve mevcut battle korunmalıdır; aksi halde tek bir geçici
/// hata PK ekranını single-live moda düşürür.
bool pkRefreshErrorMeansBattleGone(int? statusCode) {
  return statusCode == 404 || statusCode == 410;
}

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
  if (isLivePkActiveStatus(status) ||
      isLivePkStartingStatus(status) ||
      isLivePkPausedStatus(status)) {
    if (lastAuthorityAt != null &&
        clock.difference(lastAuthorityAt) < staleTtl) {
      return true;
    }
  }
  return false;
}
