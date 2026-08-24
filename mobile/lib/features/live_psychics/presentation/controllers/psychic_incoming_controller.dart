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

  PsychicRequestEntity? takeNext() {
    if (state.isEmpty) return null;
    final next = state.first;
    state = state.sublist(1);
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
