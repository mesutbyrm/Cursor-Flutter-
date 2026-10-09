import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/data/services/voice_room_debug_log.dart';

void main() {
  test('DioException: yöntem + yol + durum, sorgu dizesi yok', () {
    final opts = RequestOptions(
      path: 'https://canlifal.com/api/room/abc/summary?token=gizli',
      method: 'GET',
    );
    final err = DioException(
      requestOptions: opts,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: opts, statusCode: 401),
    );
    final out = VoiceRoomDebugLog.describeError(err);
    expect(out, 'DioException[badResponse] GET /api/room/abc/summary status=401');
    expect(out.contains('gizli'), isFalse);
  });

  test('obfuscated yığın: build_id + çerçeveler', () {
    const raw = '*** *** *** *** ***\n'
        'pid: 1, tid: 2, name 1.ui\n'
        "build_id: 'abc123'\n"
        '#00 abs 000000706b1f2c3b virt 00000000003a2c3b _kDartIsolateSnapshotInstructions+0x2a1c3b\n'
        '#01 abs 000000706b1f1111 virt 0000000000391111 _kDartIsolateSnapshotInstructions+0x290111\n';
    final out = VoiceRoomDebugLog.stackSummary(StackTrace.fromString(raw));
    expect(out, startsWith('*** *** *** *** *** | pid: 1'));
    expect(out.contains("build_id: 'abc123' | #00 abs"), isTrue);
    expect(out.contains('#01 abs'), isTrue);
  });

  test('normal yığın: ilk satırlar korunur', () {
    final out = VoiceRoomDebugLog.stackSummary(
      StackTrace.fromString('a.dart 1:1\nb.dart 2:2'),
    );
    expect(out, 'a.dart 1:1 | b.dart 2:2');
  });
}
