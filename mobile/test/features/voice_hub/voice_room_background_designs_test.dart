
import 'package:canlifal_social/features/voice_hub/presentation/sheets/voice_room_background_designs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('her tür için 50 benzersiz tasarım', () {
    final ids = <String>{};
    for (final t in VoiceRoomBgTier.values) {
      final list = voiceRoomBgDesigns(t);
      expect(list.length, 50);
      ids.addAll(list.map((d) => d.id));
    }
    expect(ids.length, 150);
  });

  test('oda türü → set kilidi', () {
    expect(voiceRoomBgTierAllowed(VoiceRoomBgTier.free, VoiceRoomBgTier.free),
        isTrue);
    expect(voiceRoomBgTierAllowed(VoiceRoomBgTier.free, VoiceRoomBgTier.vip),
        isFalse);
    expect(voiceRoomBgTierAllowed(VoiceRoomBgTier.vip, VoiceRoomBgTier.paid),
        isTrue);
    expect(
      voiceRoomBgTierAllowed(
        VoiceRoomBgTier.free,
        VoiceRoomBgTier.vip,
        isSiteAdmin: true,
      ),
      isTrue,
    );
  });

  test('PNG üretilir (varsayılan + her türden örnek)', () async {
    final out = <String>[];
    for (final d in [
      voiceRoomBgDefaultDesign,
      voiceRoomBgDesigns(VoiceRoomBgTier.free)[3],
      voiceRoomBgDesigns(VoiceRoomBgTier.paid)[3],
      voiceRoomBgDesigns(VoiceRoomBgTier.vip)[3],
    ]) {
      final f = await renderVoiceRoomBgDesignPng(d);
      expect(f.lengthSync(), greaterThan(2000));
      out.add(f.path);
    }
    expect(out.length, 4);
  });
}
