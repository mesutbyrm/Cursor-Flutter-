import '../../../core/util/json_util.dart';

/// `GET /api/live/guest/list` yanıtı.
class LiveGuestListSnapshot {
  const LiveGuestListSnapshot({
    this.streamId,
    this.count = 0,
    this.maxGuests = 8,
    this.gridSlots = 2,
    this.guests = const [],
  });

  final String? streamId;
  final int count;
  final int maxGuests;
  final int gridSlots;
  final List<Map<String, dynamic>> guests;

  factory LiveGuestListSnapshot.fromJson(Map<String, dynamic> json) {
    final rawGuests = json['guests'];
    final guests = <Map<String, dynamic>>[];
    if (rawGuests is List) {
      for (final g in rawGuests) {
        if (g is Map) guests.add(asJsonMap(g));
      }
    }
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
    );
  }

  /// `co_broadcast` / grid provider ile uyumlu liste.
  List<Map<String, dynamic>> toCoBroadcasters() {
    return guests
        .map((g) => {
              'userId': pick(g, ['userId', 'user_id', 'id'])?.toString() ?? '',
              'userName': pick(g, ['userName', 'username', 'displayName'])
                  ?.toString(),
              'displayName': pick(g, ['displayName', 'userName', 'username'])
                  ?.toString(),
              'agoraUid': g['agoraUid'] ?? g['uid'],
              'slotIndex': g['slotIndex'] ?? g['seatIndex'],
              'status': g['status'] ?? 'live',
            })
        .where((g) => (g['userId'] as String).isNotEmpty)
        .toList(growable: false);
  }
}
