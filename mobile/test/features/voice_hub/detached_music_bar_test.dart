import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_dj_state.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_web_music_bar.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('detached mini player builds without ErrorWidget', (tester) async {
    final errors = <Object>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.exception);
      prev?.call(d);
    };

    final track = MusicQueueItem(
      id: 't1',
      title: 'Test Song',
      youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      createdAt: DateTime(2026, 1, 1),
    );
    final dj = ChatRoomDjState(
      playing: true,
      nowPlaying: track,
      musicQueue: [track],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(PersistCookieJar()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VoiceRoomWebMusicBar(
              dj: dj,
              roomLiveKey: 'room-cuid-123456789012',
              detachedMiniPlayer: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Bir bölüm yüklenemedi'), findsNothing);
  });
}
