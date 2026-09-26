import '../../domain/entities/chat_room_presence.dart';

/// Backend join onayı olmadan kendini presence listesine ekleme (sahte "odadayım").
bool shouldAugmentPresenceWithSelf({
  required bool backendJoinAcknowledged,
  required List<ChatRoomPresence> members,
  required String? selfId,
}) {
  if (!backendJoinAcknowledged) return false;
  if (selfId == null || selfId.trim().isEmpty) return false;
  return !members.any((p) => p.id == selfId);
}

/// Backend join onayı + presence listesinde self → UI `selfInRoom`.
bool resolveSelfInRoomFromBackend({
  required bool backendJoinAcknowledged,
  required bool listedInPresence,
}) {
  return backendJoinAcknowledged && listedInPresence;
}

/// `selfInRoom` bayrağını tek bir eksik anlık görüntüde düşürmeyen izleyici.
///
/// Sunucu `GET /state` yanıtında katılımcı listesini bazen kullanıcıyı
/// içermeden döndürüyor (kısa tutarlılık penceresi, heartbeat yenilenirken).
/// Her böyle yanıtta `selfInRoom` false olduğu için üst bardaki sayaç bir
/// anda "0 çevrimiçi"ye düşüyor, koltuk ve mikrofon kontrolleri kayboluyordu.
///
/// Kural: giriş onayı yoksa her zaman `false`. Listede varsa `true`.
/// Listede yoksa — yanıt hiç üye taşımıyorsa bilgi yok sayılır (önceki durum
/// korunur), üye taşıyorsa düşürmeden önce [tolerance] kadar ardışık onay
/// beklenir. Böylece sunucunun gerçekten "odada değilsin" demesi yine
/// uygulanır; tek seferlik yarış durumu ise UI'ı bozmaz.
class SelfPresenceTracker {
  SelfPresenceTracker({this.tolerance = 2});

  /// Kaç ardışık "listede yok" yanıtından sonra `selfInRoom` düşürülür.
  final int tolerance;

  int _missStreak = 0;

  /// Yeniden odaya girişte sayaç sıfırlanır.
  void reset() => _missStreak = 0;

  int get missStreak => _missStreak;

  bool resolve({
    required bool previous,
    required bool backendJoinAcknowledged,
    required bool listedInPresence,
    required bool snapshotHasMembers,
  }) {
    if (!backendJoinAcknowledged) {
      _missStreak = 0;
      return false;
    }
    if (listedInPresence) {
      _missStreak = 0;
      return true;
    }
    if (!snapshotHasMembers) {
      // Boş liste bilgi taşımaz; eski durum korunur.
      return previous;
    }
    _missStreak++;
    if (_missStreak < tolerance) return previous;
    return false;
  }
}

/// Isınma/yeniden katılımda geri alınacak koltuk.
///
/// Heartbeat düştüğünde presence yeniden gönderiliyor ama koltuk talebi
/// kapalıydı; sunucu presence kaydını düşürdüyse kullanıcı odaya geri
/// giriyor fakat koltuğu boş kalıyordu ("koltuktan düşme"). Kullanıcının en
/// son doğrulanmış koltuğu biliniyorsa aynı koltuk yeniden istenir.
int? resolveRejoinSeatIndex({
  required int? currentSeatIndex,
  required int? lastConfirmedSeatIndex,
}) {
  if (currentSeatIndex != null && currentSeatIndex >= 1) {
    return currentSeatIndex;
  }
  if (lastConfirmedSeatIndex != null && lastConfirmedSeatIndex >= 1) {
    return lastConfirmedSeatIndex;
  }
  return null;
}

List<ChatRoomPresence> augmentPresenceWithSelf({
  required bool backendJoinAcknowledged,
  required List<ChatRoomPresence> members,
  required ChatRoomPresence self,
}) {
  if (!shouldAugmentPresenceWithSelf(
    backendJoinAcknowledged: backendJoinAcknowledged,
    members: members,
    selfId: self.id,
  )) {
    return members;
  }
  return [...members, self];
}
