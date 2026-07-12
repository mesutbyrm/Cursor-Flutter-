import 'pk_room_models.dart';

/// Gelen PK daveti bu yayın sahibine mi ait?
bool isLivePkInviteRecipient(
  PkRoomMatch match, {
  required String myStreamId,
  String? myUserId,
}) {
  if (!match.isPending || match.mode != PkRoomMode.oneVsOne) return false;
  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';

  if (sid.isEmpty) {
    if (uid.isEmpty) return false;
    if (match.hostUserId == uid) return false;
    return match.seats.any((s) => s.userId == uid);
  }

  if (match.hostStreamId == sid) return false;

  if (match.seats.any((s) => s.streamId == sid)) return true;

  if (uid.isNotEmpty) {
    if (match.hostUserId == uid) return false;
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
  final hostStream = battle['hostStreamId']?.toString();
  if (hostStream != null && hostStream.isNotEmpty && hostStream == sid) {
    return false;
  }

  final seats = battle['seats'];
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

  final opponentStream = battle['opponentStreamId']?.toString();
  if (opponentStream != null && opponentStream.isNotEmpty && opponentStream == sid) {
    return true;
  }
  return false;
}
