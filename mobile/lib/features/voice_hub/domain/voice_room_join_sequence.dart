/// Backend contract join sırası — Flutter bu adımları atlamaz / öne almaz.
///
/// `state → presence → SSE → messages → seats → TRTC`
abstract final class VoiceRoomJoinSequence {
  static const steps = <String>[
    'auth',
    'state',
    'presence',
    'sse',
    'messages',
    'seats',
    'trtc',
  ];

  static int indexOf(String step) => steps.indexOf(step);

  static bool isBefore(String a, String b) => indexOf(a) < indexOf(b);
}
