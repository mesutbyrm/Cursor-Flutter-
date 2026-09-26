import '../data/pk_models.dart';

/// Rövanş hedefi — biten PK'dan rakip oda/yayın ve kullanıcı.
typedef PkRematchTarget = ({String contextId, String userId});

/// Biten savaşta karşı tarafı çözer.
///
/// [myContextId] bu oturumun oda/yayın anahtarıdır; rakip, savaşın diğer
/// tarafıdır. Taraflar çözülemiyorsa (anahtar eşleşmiyor veya sunucu oda
/// bilgisi göndermemiş) `null` döner ve rövanş teklif edilmez — yanlış
/// kişiye davet göndermektense teklifi hiç göstermemek doğrudur.
PkRematchTarget? resolvePkRematchTarget({
  required PkBattle battle,
  required String myContextId,
}) {
  final me = myContextId.trim();
  if (me.isEmpty) return null;

  final room1 = battle.room1Id.trim();
  final room2 = battle.room2Id.trim();

  if (room1 == me && room2.isNotEmpty) {
    return (contextId: room2, userId: battle.user2Id.trim());
  }
  if (room2 == me && room1.isNotEmpty) {
    return (contextId: room1, userId: battle.user1Id.trim());
  }
  return null;
}
