import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/api_response.dart';
import 'package:canlifal_social/services/models/stream_comment.dart';
import 'package:canlifal_social/services/models/stream_summary.dart';

void main() {
  group('StreamSummary', () {
    test('parses live stream card', () {
      final s = StreamSummary.fromJson({
        'id': 's1',
        'title': 'Fal Yayını',
        'category': 'fal',
        'viewerCount': 42,
        'isLive': true,
        'user': {'id': 'u1', 'displayName': 'Host'},
        'thumbnailUrl': 'https://cdn.example/cover.jpg',
      });
      expect(s.id, 's1');
      expect(s.title, 'Fal Yayını');
      expect(s.viewerCount, 42);
      expect(s.hostUserId, 'u1');
      expect(s.streamerName, 'Host');
    });

    test('marks ended streams offline', () {
      final s = StreamSummary.fromJson({
        'id': 's2',
        'title': 'Bitti',
        'status': 'ended',
      });
      expect(s.isLive, isFalse);
    });
  });

  group('StreamComment', () {
    test('parses comment with user', () {
      final c = StreamComment.fromJson({
        'id': 'c1',
        'content': 'Harika!',
        'createdAt': '2026-07-16T12:00:00.000Z',
        'user': {'id': 'u1', 'username': 'ali'},
      });
      expect(c.content, 'Harika!');
      expect(c.userName, 'ali');
    });
  });

  group('getStreams parseResponse', () {
    test('unwraps paginated list', () {
      final parsed = parseResponse<List<StreamSummary>>(
        {
          'success': true,
          'data': {
            'streams': [
              {'id': '1', 'title': 'A'},
              {'id': '2', 'title': 'B'},
            ],
          },
        },
        fromData: (data) {
          final list = data is Map
              ? (data['streams'] as List)
                  .map((e) => StreamSummary.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ))
                  .toList()
              : <StreamSummary>[];
          return list;
        },
      );
      expect(parsed.success, isTrue);
      expect(parsed.data, hasLength(2));
    });
  });
}
