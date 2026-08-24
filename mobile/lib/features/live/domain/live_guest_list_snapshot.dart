import '../../../core/util/json_util.dart';
import 'live_guest_layout_resolver.dart';

/// `GET /api/live/guest/list` yanıtı.
class LiveGuestListSnapshot {
  const LiveGuestListSnapshot({
    this.streamId,
    this.count = 0,
    this.maxGuests = 8,
    this.gridSlots = 2,
    this.guests = const [],
    this.joinRequests = const [],
  });

  final String? streamId;
  final int count;
  final int maxGuests;
  final int gridSlots;
  final List<Map<String, dynamic>> guests;
  final List<Map<String, dynamic>> joinRequests;

  factory LiveGuestListSnapshot.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return [
        for (final g in raw)
          if (g is Map) asJsonMap(g),
      ];
    }

    final guests = parseList(json['guests']);
    final joinRequests = parseList(
      json['joinRequests'] ??
          json['pendingRequests'] ??
          json['requests'] ??
          json['pending'],
    );

    return LiveGuestListSnapshot(
      streamId: pick(json, ['streamId', 'stream_id'])?.toString(),
      count: asInt(json['count']),
      maxGuests: asInt(json['maxGuests'] ?? json['max_guests']) == 0
          ? 8
          : asInt(json['maxGuests'] ?? json['max_guests']),
      gridSlots: asInt(json['gridSlots'] ?? json['grid_slots']) == 0
          ? 2
          : asInt(json['gridSlots'] ?? json['grid_slots']),
      guests: guests,
      joinRequests: joinRequests,
    );
  }

  /// `co_broadcast` / grid provider ile uyumlu liste.
  List<Map<String, dynamic>> toCoBroadcasters() {
    return guests
        .map((g) => {
              'userId': pick(g, ['userId', 'user_id', 'id'])?.toString() ?? '',
              'userName': pick(g, ['displayName', 'name', 'userName', 'username'])
                  ?.toString(),
              'displayName':
                  pick(g, ['displayName', 'name', 'userName', 'username'])
                      ?.toString(),
              'agoraUid': g['agoraUid'] ?? g['uid'],
              'slotIndex': g['slotIndex'] ?? g['seatIndex'],
              'status': g['status'] ?? 'live',
              'jeton': parseGuestJeton(g),
              'jetonEarned': parseGuestJeton(g),
            })
        .where((g) => (g['userId'] as String).isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> toJoinRequests() {
    return joinRequests
        .map((g) => {
              'userId': pick(g, ['userId', 'user_id', 'id'])?.toString() ?? '',
              'userName': pick(g, ['displayName', 'name', 'userName', 'username'])
                  ?.toString(),
              'displayName':
                  pick(g, ['displayName', 'name', 'userName', 'username'])
                      ?.toString(),
              'status': g['status'] ?? 'pending',
              'requestedAt': g['requestedAt'] ?? g['createdAt'],
            })
        .where((g) => (g['userId'] as String).isNotEmpty)
        .toList(growable: false);
  }
}
