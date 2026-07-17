import 'package:canlifal_social/features/live/domain/live_guest_list_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveGuestListSnapshot', () {
    test('fromJson parses prod guest list shape', () {
      final snap = LiveGuestListSnapshot.fromJson({
        'count': 1,
        'maxGuests': 8,
        'gridSlots': 2,
        'streamId': 'stream-1',
        'guests': [
          {
            'userId': 'u1',
            'displayName': 'Konuk',
            'agoraUid': 42,
            'slotIndex': 1,
          },
        ],
      });
      expect(snap.streamId, 'stream-1');
      expect(snap.count, 1);
      expect(snap.maxGuests, 8);
      expect(snap.gridSlots, 2);
      expect(snap.guests, hasLength(1));
    });

    test('toCoBroadcasters maps grid fields', () {
      const snap = LiveGuestListSnapshot(
        guests: [
          {
            'userId': 'u1',
            'displayName': 'Ali',
            'agoraUid': 7,
            'slotIndex': 1,
          },
        ],
      );
      final co = snap.toCoBroadcasters();
      expect(co, hasLength(1));
      expect(co.first['userId'], 'u1');
      expect(co.first['displayName'], 'Ali');
      expect(co.first['agoraUid'], 7);
      expect(co.first['slotIndex'], 1);
    });

    test('fromJson keeps pending joinRequests', () {
      final snap = LiveGuestListSnapshot.fromJson({
        'streamId': 's1',
        'guests': [],
        'joinRequests': [
          {'userId': 'u2', 'displayName': 'Ayşe', 'status': 'pending'},
        ],
      });
      expect(snap.joinRequests, hasLength(1));
      final reqs = snap.toJoinRequests();
      expect(reqs.first['userId'], 'u2');
      expect(reqs.first['displayName'], 'Ayşe');
    });
  });
}
