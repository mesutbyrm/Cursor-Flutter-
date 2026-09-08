import 'package:canlifal_social/features/fortune/domain/fortune_type_slug.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_invite_dedup_provider.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_sse_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FortuneTypeSlug maps catalog slugs to API paths', () {
    expect(FortuneTypeSlug.resolve('iskambil'), 'iskambil-fali');
    expect(FortuneTypeSlug.resolve('pendul'), 'pendul-fali');
    expect(FortuneTypeSlug.resolve('runik'), 'runik-fali');
    expect(FortuneTypeSlug.resolve('cin-fali'), 'cin-fali');
  });

  test('chatRoomSseEventTypeFrom recognizes speak request aliases', () {
    expect(chatRoomSseEventTypeFrom('speak_request'),
        ChatRoomSseEventType.speakRequest);
    expect(chatRoomSseEventTypeFrom('hand_raise'),
        ChatRoomSseEventType.speakRequest);
  });

  test('live invite dedup keys are namespaced', () {
    expect(livePkInviteDedupKey('abc'), 'pk:abc');
    expect(liveCoBroadcastInviteDedupKey('xyz'), 'co:xyz');
  });
}
