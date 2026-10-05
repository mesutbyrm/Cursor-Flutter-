import 'room_event_scope.dart';

/// Sesli oda SSE/hediye olayının aktif oturuma ait olup olmadığını doğrular.
bool voiceRoomAcceptsAttachedSseEvent({
  required bool sessionActive,
  required String attachedRoomKey,
  required String eventRoomKey,
  String? activeLiveKey,
  String? presenceApiKey,
  String? alternateRoomId,
}) {
  if (!sessionActive) return false;
  final attached = attachedRoomKey.trim();
  if (attached.isEmpty) return false;

  final eventKey = eventRoomKey.trim();
  if (eventKey.isNotEmpty && attached != eventKey) {
    return false;
  }

  final canonical = (presenceApiKey ?? activeLiveKey ?? attached).trim();
  if (canonical.isEmpty) return attached == eventKey || eventKey.isEmpty;

  if (eventKey.isEmpty) return true;

  return roomEventMatchesActiveRoom(
    {'roomId': eventKey},
    canonical,
    alternateRoomId: alternateRoomId,
  );
}
