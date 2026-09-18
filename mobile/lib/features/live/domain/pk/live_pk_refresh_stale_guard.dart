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

/// Boş/hatalı `refresh` yanıtında mevcut PK battle haritasını korur
/// (single-live düşüşünü önler).
///
/// **Ürün kararı (2026-09-18): süren bir maçta PK ekranı kalır.** Sunucudan
/// doğrulama gelmemesi "maç bitti" demek değildir; zayıf ağda maç sürerken
/// ekranın düşmesi, bitmiş bir maçın birkaç saniye fazla durmasından çok daha
/// kötü bir deneyim.
///
/// Önceden burada 90 saniyelik bir istemci sayacı vardı: son doğrulamadan 90 sn
/// sonra battle siliniyordu. Varsayılan maç süresi 180 sn olduğu için 90 sn'yi
/// aşan bir ağ sorunu, maç hâlâ canlıyken PK ekranını düşürüyordu.
///
/// Ekranın sonsuza kadar takılı kalmaması için tek çıkış **maçın kendi bitiş
/// zamanıdır** (`endsAt`) — istemci sayacı değil, sunucudan gelen (ya da
/// `startedAt + duration`'dan türetilen) gerçek. Bitiş zamanı + [graceAfterEnd]
/// geçtiyse sunucunun artık doğrulama göndermeyeceği kabul edilir.
bool shouldRetainPkBattleOnEmptyRefresh({
  required Map<String, dynamic>? battle,
  required String? status,
  Duration graceAfterEnd = const Duration(minutes: 2),
  DateTime? now,
}) {
  if (battle == null || battle.isEmpty) return false;
  final clock = now ?? DateTime.now();

  if (isPkInvitePendingStatus(status)) return true;
  if (isLivePkBroadcastStage(battle, status)) return true;

  if (isLivePkActiveStatus(status) ||
      isLivePkStartingStatus(status) ||
      isLivePkPausedStatus(status)) {
    final endsAt = DateTime.tryParse('${battle['endsAt'] ?? ''}');
    // Bitiş zamanı bilinmiyorsa koruma tarafında kal.
    if (endsAt == null) return true;
    return clock.isBefore(endsAt.add(graceAfterEnd));
  }

  return false;
}
