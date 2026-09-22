import 'dart:convert';

import 'package:canlifal_social/features/cfc_arena/domain/cfc_arena_context.dart';
import 'package:canlifal_social/features/cfc_arena/domain/cfc_arena_contest_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCfcContestList reads production data.contests', () {
    const raw = '''
{"success":true,"data":{"contests":[{"id":"c1","name":"Test","status":"active","isFeatured":true,"type":"individual","scope":"general"}]}}
''';
    final list = parseCfcContestList(jsonDecode(raw));
    expect(list, hasLength(1));
    expect(list.first['id'], 'c1');
  });

  test('filterContestsForSurface matches featured live contest', () {
    final contest = {
      'id': 'c1',
      'status': 'active',
      'isFeatured': true,
      'isPublic': true,
      'type': 'individual',
      'scope': 'general',
      'scoringMetrics':
          '[{"metric":"viewer_count","weight":1},{"metric":"room_engagement","weight":1}]',
    };
    final live = filterContestsForSurface([contest], CfcArenaSurface.liveBroadcast);
    final voice = filterContestsForSurface([contest], CfcArenaSurface.voiceRoom);
    expect(live, isNotEmpty);
    expect(voice, isNotEmpty);
  });
}
