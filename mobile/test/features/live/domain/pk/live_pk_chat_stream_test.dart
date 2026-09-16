import 'package:canlifal_social/features/live/domain/pk/live_pk_chat_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLivePkChatStreamId', () {
    test('prefers challenger host stream', () {
      expect(
        resolveLivePkChatStreamId({
          'liveStreamId': 'host-1',
          'opponentLiveStreamId': 'opp-2',
        }),
        'host-1',
      );
    });

    test('falls back to opponent when host missing', () {
      expect(
        resolveLivePkChatStreamId({
          'opponentLiveStreamId': 'opp-2',
        }),
        'opp-2',
      );
    });
  });

  group('livePkEffectiveChatStreamId', () {
    test('uses unified room when battle has host stream', () {
      expect(
        livePkEffectiveChatStreamId(
          battle: {'liveStreamId': 'host-1'},
          myStreamId: 'my-own',
        ),
        'host-1',
      );
    });

    test('falls back to my stream when battle empty', () {
      expect(
        livePkEffectiveChatStreamId(
          battle: null,
          myStreamId: 'my-own',
        ),
        'my-own',
      );
    });
  });
}
