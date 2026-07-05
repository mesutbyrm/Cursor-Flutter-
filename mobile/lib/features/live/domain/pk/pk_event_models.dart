import 'package:flutter/material.dart';

import '../../../../core/util/json_util.dart';

/// PK premium maç-içi etkinlik türleri (yayın sahibi başlatır).
enum PkEventType {
  luckyGift('lucky_gift', 'Şanslı Hediye', '🍀', Color(0xFF66E36F)),
  goldenMinute('golden_minute', 'Altın Dakika', '⭐', Color(0xFFFFD54F)),
  doubleScore('double_score', 'Çift Puan', '✖️', Color(0xFF40C4FF)),
  finalFrenzy('final_frenzy', 'Final Çılgınlığı', '🔥', Color(0xFFFF4D4D));

  const PkEventType(this.wire, this.label, this.emoji, this.color);

  final String wire;
  final String label;
  final String emoji;
  final Color color;

  static PkEventType? parse(String? v) {
    for (final t in values) {
      if (t.wire == (v ?? '').toLowerCase()) return t;
    }
    return null;
  }
}

/// Aktif/bitmiş PK etkinliği — `/api/pk/{id}/events`.
/// Çarpan yalnızca PK puanına uygulanır; gerçek jeton/gelir değişmez.
class PkMatchEvent {
  const PkMatchEvent({
    required this.id,
    required this.type,
    this.multiplier = 2,
    this.remainingSec = 0,
    this.active = true,
  });

  factory PkMatchEvent.fromJson(Map<String, dynamic> json) {
    var remaining = asInt(pick(json, ['remainingSec', 'secondsLeft', 'remaining']));
    final endsAtRaw = pick(json, ['endsAt', 'expiresAt', 'endAt']);
    if (remaining <= 0 && endsAtRaw != null) {
      final endsAt = DateTime.tryParse(endsAtRaw.toString());
      if (endsAt != null) {
        remaining = endsAt.difference(DateTime.now()).inSeconds;
        if (remaining < 0) remaining = 0;
      }
    }
    final statusActive = pick(json, ['active', 'isActive']);
    return PkMatchEvent(
      id: (pick(json, ['id', 'eventId']) ?? '').toString(),
      type: PkEventType.parse(pick(json, ['type', 'eventType'])?.toString()) ??
          PkEventType.doubleScore,
      multiplier: () {
        final m = asInt(pick(json, ['multiplier', 'factor']));
        return m > 0 ? m : 2;
      }(),
      remainingSec: remaining,
      active: statusActive is bool ? statusActive : remaining > 0,
    );
  }

  final String id;
  final PkEventType type;
  final int multiplier;
  final int remainingSec;
  final bool active;

  bool get isLive => active && remainingSec > 0;
}
