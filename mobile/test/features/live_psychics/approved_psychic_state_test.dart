import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kontrol bitti + profil yok → kesin falcı değil', () {
    const s = ApprovedPsychicState(checked: true);
    expect(s.definitelyNotTeller, isTrue);
  });

  test('ağ hatası (checkFailed) → «falcı değil» denmez, rota serbest', () {
    const s = ApprovedPsychicState(checked: true, checkFailed: true);
    expect(s.definitelyNotTeller, isFalse);
  });

  test('henüz kontrol edilmedi → yönlendirme yok', () {
    const s = ApprovedPsychicState(loading: true);
    expect(s.definitelyNotTeller, isFalse);
  });

  test('onaylı falcı → falcı değil değil', () {
    const s = ApprovedPsychicState(
      checked: true,
      profile: PsychicEntity(id: 't', name: 'F', isOnline: true),
    );
    expect(s.isApprovedTeller == s.profile!.isUsable, isTrue);
    expect(s.definitelyNotTeller, isFalse);
  });
}
