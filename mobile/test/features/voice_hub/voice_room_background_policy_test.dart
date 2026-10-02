import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_background_policy.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceRoomEntity _room({String? type, bool? vip}) => VoiceRoomEntity(
      id: 'r1',
      slug: 'oda',
      nameTr: 'Oda',
      roomType: type,
      isVip: vip,
    );

void main() {
  test('ücretsiz oda kilitli, ücretli (NORMAL/VIP) açık', () {
    expect(voiceRoomBackgroundUnlocked(_room(type: 'FREE')), isFalse);
    expect(voiceRoomBackgroundUnlocked(_room(type: 'free')), isFalse);
    expect(voiceRoomBackgroundUnlocked(_room(type: 'NORMAL')), isTrue);
    expect(voiceRoomBackgroundUnlocked(_room(type: 'VIP')), isTrue);
  });

  test('site yöneticisi ücretsiz odada da değiştirebilir', () {
    expect(
      voiceRoomBackgroundUnlocked(_room(type: 'FREE'), isSiteAdmin: true),
      isTrue,
    );
  });

  test('oda türü bilinmiyorsa kilitlenmez (sunucu karar verir)', () {
    expect(voiceRoomBackgroundUnlocked(_room()), isTrue);
  });
}
