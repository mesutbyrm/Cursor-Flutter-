/// Sunucu `pk` olaylarının TİP'e göre kesin sınıflandırması.
///
/// Backend (`lib/pk-state.ts`, `lib/gift-pk-score.ts`) her `pk` olayına bir
/// `eventType` koyar: `PK_STARTING`, `PK_STARTED`, `PK_SCORE`, `PK_PAUSED`,
/// `PK_RESUMED`, `PK_ENDED`, `PK_REQUEST*`, `PK_EXPIRED`… İstemci metin/kelime
/// ("hediye", "jeton") üzerinden DEĞİL, yalnızca bu tipten karar verir.
///
/// ÖNEMLİ: `PK_SCORE` (hediye puanı) bir *davet değildir* ve `status` taşımaz.
/// Eskiden status'suz payload `pending` sayılıp "PK isteği" popup'ı açıyordu.
enum PkWireKind {
  /// Gerçek PK daveti (oda-vs-oda): yalnızca bu tip davet popup'ı açar.
  invite,

  /// Oda içi PK geri sayımı (`starting`) — davet DEĞİL.
  starting,
  started,

  /// Hediye puanı — yalnızca skor yamasıdır; durum/süre değiştirmez.
  score,
  paused,
  resumed,
  ended,
  cancelled,
  rejected,
  expired,

  /// Tam durum (`PK_STATE` veya status taşıyan genel PK payload'ı).
  state,
  unknown,
}

/// Bir `pk` SSE/REST payload'ının sınıflandırılmış hali.
class PkWireEvent {
  const PkWireEvent({
    required this.kind,
    required this.battleId,
    required this.raw,
    this.inRoom = false,
  });

  final PkWireKind kind;
  final String battleId;

  /// Normalize edilmemiş ham payload (alanlar `PkRoomMatch.fromJson` ile okunur).
  final Map<String, dynamic> raw;

  /// Aynı oda içi (kullanıcı-vs-kullanıcı) PK mı? (`room1Id == room2Id` veya
  /// `scope == room_user`.)
  final bool inRoom;

  bool get isScore => kind == PkWireKind.score;
  bool get isInvite => kind == PkWireKind.invite;

  static PkWireEvent parse(Map<String, dynamic> map) {
    final data = _flatten(map);
    final id = _firstString(data, const ['battleId', 'matchId', 'pkBattleId', 'id']);
    return PkWireEvent(
      kind: classify(data),
      battleId: id,
      raw: data,
      inRoom: isInRoomPayload(data),
    );
  }

  /// `data/battle/pk/match` zarfını açar; üst düzey alanlar iç alanları ezmez
  /// (üst düzey `eventType`/`action` korunur).
  static Map<String, dynamic> _flatten(Map<String, dynamic> map) {
    final nested = map['battle'] ?? map['pk'] ?? map['match'] ?? map['data'];
    if (nested is Map) {
      return {...Map<String, dynamic>.from(nested), ...map}
        ..remove('battle')
        ..remove('pk')
        ..remove('match');
    }
    return Map<String, dynamic>.from(map);
  }

  static String _firstString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// `eventType` → tip. `eventType` yoksa `action`; o da yoksa `status`.
  static PkWireKind classify(Map<String, dynamic> m) {
    final type = (m['eventType'] ?? m['event'])?.toString().toUpperCase().trim() ?? '';
    final action = m['action']?.toString().toLowerCase().trim() ?? '';
    final status = m['status']?.toString().toLowerCase().trim() ?? '';

    PkWireKind? fromType(String t) {
      if (t.isEmpty) return null;
      if (t == 'PK_SCORE' || t.contains('SCORE')) return PkWireKind.score;
      if (t == 'PK_STARTING') return PkWireKind.starting;
      if (t == 'PK_STARTED') return PkWireKind.started;
      if (t == 'PK_PAUSED') return PkWireKind.paused;
      if (t == 'PK_RESUMED') return PkWireKind.resumed;
      if (t == 'PK_ENDED' || t == 'PK_FINISHED' || t == 'PK_COMPLETED') {
        return PkWireKind.ended;
      }
      if (t == 'PK_REQUEST_CANCELLED' || t == 'PK_CANCELLED') {
        return PkWireKind.cancelled;
      }
      if (t == 'PK_REJECTED' || t == 'PK_REQUEST_REJECTED') {
        return PkWireKind.rejected;
      }
      if (t == 'PK_EXPIRED') return PkWireKind.expired;
      if (t == 'PK_INVITE' || t == 'PK_REQUEST' || t == 'PK_REQUESTED') {
        return PkWireKind.invite;
      }
      if (t == 'PK_STATE') return PkWireKind.state;
      return null;
    }

    final byType = fromType(type);
    if (byType != null) return byType;

    switch (action) {
      case 'score_update':
      case 'score':
        return PkWireKind.score;
      case 'starting':
        return PkWireKind.starting;
      case 'started':
        return PkWireKind.started;
      case 'paused':
        return PkWireKind.paused;
      case 'resumed':
        return PkWireKind.resumed;
      case 'completed':
      case 'ended':
        return PkWireKind.ended;
      case 'cancelled':
      case 'canceled':
        return PkWireKind.cancelled;
      case 'rejected':
        return PkWireKind.rejected;
      case 'expired':
        return PkWireKind.expired;
      case 'create':
      case 'created':
      case 'invite':
      case 'request':
        return PkWireKind.invite;
    }

    // Tip/aksiyon yok: yalnızca AÇIK status taşıyan payload durum sayılır.
    // Status'suz payload asla "davet" sayılmaz (eski hata).
    if (status.isNotEmpty) {
      if (status == 'pending' || status == 'invited') return PkWireKind.invite;
      return PkWireKind.state;
    }
    return PkWireKind.unknown;
  }

  /// Oda içi PK: iki taraf da aynı oda (`room1Id == room2Id`) ya da
  /// `scope == room_user`.
  static bool isInRoomPayload(Map<String, dynamic> m) {
    final scope = m['scope']?.toString().toLowerCase().trim() ?? '';
    if (scope.contains('room_user')) return true;
    final battleType = m['battleType']?.toString().toLowerCase() ?? '';
    if (battleType.contains('room_user')) return true;
    final r1 = _firstString(m, const ['room1Id', 'stream1Id', 'voiceRoomId']);
    final r2 = _firstString(m, const ['room2Id', 'stream2Id', 'opponentVoiceRoomId']);
    return r1.isNotEmpty && r1 == r2;
  }
}
