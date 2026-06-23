import 'package:flutter_riverpod/flutter_riverpod.dart';

class PsychicPeerLeftEvent {
  const PsychicPeerLeftEvent({
    required this.sessionId,
    required this.message,
  });

  final String sessionId;
  final String message;
}

final psychicPeerLeftProvider =
    StateProvider<PsychicPeerLeftEvent?>((ref) => null);
