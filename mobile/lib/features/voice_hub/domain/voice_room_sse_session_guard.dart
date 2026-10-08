import 'room_event_scope.dart';

/// Sesli oda SSE/hediye olayının aktif oturuma ait olup olmadığını doğrular.
bool voiceRoomAcceptsAttachedSseEvent({
  required bool sessionActive,
  required String attachedRoomKey,
  required String eventRoomKey,
  String? activeLiveKey,
  String? presenceApiKey,
  String? alternateRoomId,
  bool leaveInFlight = false,
}) {
  if (!sessionActive || leaveInFlight) return false;
  final attached = attachedRoomKey.trim();
  if (attached.isEmpty) return false;

  final eventKey = eventRoomKey.trim();
  final canonical = (presenceApiKey ?? activeLiveKey ?? attached).trim();
  final active = activeLiveKey?.trim() ?? '';
  if (active.isNotEmpty &&
      eventKey.isNotEmpty &&
      !roomEventMatchesActiveRoom(
        {'roomId': eventKey},
        active,
        alternateRoomId: alternateRoomId,
        extraAlternateRoomIds: [attached],
      )) {
    return false;
  }
  if (eventKey.isEmpty) return true;
  if (canonical.isEmpty) {
    return attached == eventKey ||
        roomEventMatchesActiveRoom(
          {'roomId': eventKey},
          attached,
          alternateRoomId: alternateRoomId,
        );
  }

  return roomEventMatchesActiveRoom(
    {'roomId': eventKey},
    canonical,
    alternateRoomId: alternateRoomId,
    extraAlternateRoomIds: [attached],
  );
}
