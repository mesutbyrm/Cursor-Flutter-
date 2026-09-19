import 'package:canlifal_social/features/live/domain/pk/live_pk_side_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('broadcaster challenger sees self on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
        'challengerId': 'user-a',
        'opponentId': 'user-b',
      },
      myStreamId: 'stream-a',
      myUserId: 'user-a',
      amBroadcaster: true,
    );
    expect(layout.left.isLocalPane, isTrue);
    expect(layout.left.label, 'Admin');
    expect(layout.right.label, 'Rival');
    expect(layout.right.streamId, 'stream-b');
  });

  test('broadcaster opponent sees self on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
        'challengerId': 'user-a',
        'opponentId': 'user-b',
      },
      myStreamId: 'stream-b',
      myUserId: 'user-b',
      amBroadcaster: true,
    );
    expect(layout.left.isLocalPane, isTrue);
    expect(layout.left.label, 'Rival');
    expect(layout.right.label, 'Admin');
  });

  test('viewer sees host stream on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
      },
      myStreamId: 'stream-a',
      amBroadcaster: false,
    );
    expect(layout.left.isLocalPane, isFalse);
    expect(layout.left.streamId, 'stream-a');
    expect(layout.right.streamId, 'stream-b');
  });

  group('taraf kilidi (titreme önleme)', () {
    test('hostStream/challengerId yokken confident null döner', () {
      expect(
        resolveIAmChallengerConfident(
          battle: const {'leftName': 'A', 'rightName': 'B'},
          myStreamId: 'stream-a',
          myUserId: 'user-a',
        ),
        isNull,
      );
    });

    test('hostStream bilindiğinde stream ile güvenle çözülür', () {
      expect(
        resolveIAmChallengerConfident(
          battle: const {'liveStreamId': 'stream-a'},
          myStreamId: 'stream-a',
          myUserId: 'user-a',
        ),
        isTrue,
      );
      expect(
        resolveIAmChallengerConfident(
          battle: const {'liveStreamId': 'stream-a'},
          myStreamId: 'stream-b',
          myUserId: 'user-b',
        ),
        isFalse,
      );
    });

    test('override kararsız veriye rağmen tarafı sabitler', () {
      // Battle verisi eksik (hostStream yok) — normalde challenger değil sayılıp
      // etiketler ters yerleşirdi. Kilitli override ile Admin solda kalır.
      final layout = resolveLivePkSplitLayout(
        battle: const {
          'opponentLiveStreamId': 'stream-b',
          'leftName': 'Admin',
          'rightName': 'Rival',
          'opponentId': 'user-b',
        },
        myStreamId: 'stream-a',
        myUserId: 'user-a',
        amBroadcaster: true,
        iAmChallengerOverride: true,
      );
      expect(layout.left.isLocalPane, isTrue);
      expect(layout.left.label, 'Admin');
      expect(layout.right.label, 'Rival');
    });
  });
}
