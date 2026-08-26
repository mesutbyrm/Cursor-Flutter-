import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/gifts/domain/gift_reciprocal.dart';
import 'package:canlifal_social/features/games/domain/game_room_poll.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseReciprocalGiftHint', () {
    test('karşılıklı bayrak ve mesaj', () {
      final hint = parseReciprocalGiftHint({
        'isReciprocal': true,
        'message': 'Daha önce hediyeleştiniz',
      });
      expect(hint.isMutual, isTrue);
      expect(hint.show, isTrue);
      expect(hint.message, 'Daha önce hediyeleştiniz');
    });

    test('nested data ve boş gövde', () {
      expect(
        parseReciprocalGiftHint({
          'data': {'reciprocal': true},
        }).isMutual,
        isTrue,
      );
      expect(parseReciprocalGiftHint({}).show, isFalse);
    });
  });

  test('oyun poll yalnızca resumed iken çalışır', () {
    expect(gameRoomPollAllowed(null), isTrue);
    expect(gameRoomPollAllowed(AppLifecycleState.resumed), isTrue);
    expect(gameRoomPollAllowed(AppLifecycleState.paused), isFalse);
    expect(gameRoomPollAllowed(AppLifecycleState.hidden), isFalse);
  });

  test('hediye reciprocal ve celebrity posts uçları', () {
    expect(ApiEndpoints.giftsCheckReciprocal, '/api/gifts/check-reciprocal');
    expect(ApiEndpoints.celebrityPosts('c1'), '/api/celebrities/c1/posts');
    expect(ApiEndpoints.fanClubPosts('f1'), '/api/fan-clubs/f1/posts');
  });
}
