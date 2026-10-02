import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/psychic_event_log.dart';
import '../../domain/entities/psychic_request_entity.dart';

class PsychicIncomingQueue extends Notifier<List<PsychicRequestEntity>> {
  @override
  List<PsychicRequestEntity> build() => const [];

  void enqueue(PsychicRequestEntity request) {
    if (request.sessionId.isEmpty || !request.isPending) return;
    PsychicEventLog.requestReceive(sessionId: request.sessionId);
    final list = [...state];
    list.removeWhere((r) => r.sessionId == request.sessionId);
    list.insert(0, request);
    state = list;
  }

  /// Danışan en fazla bu kadar bekler; sunucu bekleyen kayıtları süresiz
  /// tuttuğundan daha eski talepler ölüdür ve yeni talebin önüne geçmemeli.
  static const maxRequestAge = Duration(seconds: 175);

  /// Bayat talepleri eler, kalanlardan EN YENİSİNİ döndürür (poll yanıtı
  /// yeniden-eskiye gelir; sıraya eklenme sırası güvenilir değildir).
  PsychicRequestEntity? takeNext() {
    final now = DateTime.now();
    final fresh = state.where((r) {
      final at = r.createdAt;
      return at == null || now.difference(at.toLocal()) <= maxRequestAge;
    }).toList();
    if (fresh.isEmpty) {
      if (state.isNotEmpty) state = const [];
      return null;
    }
    var next = fresh.first;
    for (final r in fresh) {
      final a = r.createdAt;
      final b = next.createdAt;
      if (a != null && (b == null || a.isAfter(b))) next = r;
    }
    state = fresh.where((r) => r.sessionId != next.sessionId).toList();
    return next;
  }

  void remove(String sessionId) {
    state = state.where((r) => r.sessionId != sessionId).toList(growable: false);
  }

  void clear() => state = const [];
}

final psychicIncomingQueueProvider =
    NotifierProvider<PsychicIncomingQueue, List<PsychicRequestEntity>>(
  PsychicIncomingQueue.new,
);

final psychicIncomingPresentingProvider = StateProvider<bool>((ref) => false);

final psychicDismissedSessionsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
