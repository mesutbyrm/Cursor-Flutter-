import 'pk_room_models.dart';

/// Gelen PK daveti bu yayın sahibine mi ait?
bool isLivePkInviteRecipient(
  PkRoomMatch match, {
  required String myStreamId,
  String? myUserId,
}) {
  if (!match.isPending) return false;
  if (match.mode != PkRoomMode.oneVsOne) return false;

  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';

  if (uid.isNotEmpty && match.hostUserId == uid) return false;
  if (sid.isNotEmpty && match.hostStreamId == sid) return false;

  if (uid.isNotEmpty && match.opponentUserId == uid) return true;
  if (sid.isNotEmpty && match.opponentStreamId == sid) return true;

  if (sid.isEmpty) {
    if (uid.isEmpty) return false;
    return match.seats.any((s) => s.userId == uid);
  }

  if (match.seats.any((s) => s.streamId == sid)) return true;

  if (uid.isNotEmpty) {
    for (final seat in match.seats) {
      if (seat.userId == uid) return true;
    }
  }

  return match.seats.any(
    (s) =>
        s.streamId == sid &&
        s.streamId != null &&
        s.streamId!.isNotEmpty &&
        s.streamId != match.hostStreamId,
  );
}

bool isLivePkInviteRecipientMap(
  Map<String, dynamic> battle, {
  required String myStreamId,
  String? myUserId,
}) {
  final status = battle['status']?.toString() ?? '';
  if (status != 'pending') return false;
  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';
  final hostStream =
      battle['hostStreamId']?.toString() ?? battle['liveStreamId']?.toString();
  final hostUser =
      battle['hostUserId']?.toString() ?? battle['challengerId']?.toString();
  final opponentStream = battle['opponentStreamId']?.toString() ??
      battle['opponentLiveStreamId']?.toString();
  final opponentUser =
      battle['opponentUserId']?.toString() ?? battle['opponentId']?.toString();

  if (hostStream != null && hostStream.isNotEmpty && hostStream == sid) {
    return false;
  }
  if (uid.isNotEmpty && hostUser == uid) return false;

  if (uid.isNotEmpty && opponentUser == uid) return true;
  if (sid.isNotEmpty && opponentStream == sid) return true;

  final seats = battle['seats'] ?? battle['participants'];
  if (seats is List) {
    for (final raw in seats) {
      if (raw is! Map) continue;
      final seat = Map<String, dynamic>.from(raw);
      if (sid.isNotEmpty && seat['streamId']?.toString() == sid) return true;
      if (uid.isNotEmpty && seat['userId']?.toString() == uid) {
        if (hostStream == null || seat['streamId']?.toString() != hostStream) {
          return true;
        }
      }
    }
  }

  final opponent = battle['opponent'];
  if (opponent is Map) {
    final op = Map<String, dynamic>.from(opponent);
    if (uid.isNotEmpty && op['userId']?.toString() == uid) return true;
    if (sid.isNotEmpty && op['streamId']?.toString() == sid) return true;
  }

  if (opponentStream != null && opponentStream.isNotEmpty && opponentStream == sid) {
    return true;
  }
  return false;
}
