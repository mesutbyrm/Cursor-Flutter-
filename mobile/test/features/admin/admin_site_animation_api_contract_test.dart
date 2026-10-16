import 'package:canlifal_social/features/admin/domain/admin_site_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toApiJson sunucunun kabul ettiği alan ve değerleri üretir', () {
    const a = AdminSiteAnimation(
      id: 'x1',
      name: 'Altın Giriş',
      category: AdminSiteAnimationCategory.profileFrame,
      membership: AdminSiteAnimationMembership.normal,
      animationType: 'mp4',
      assetUrl: 'https://cdn/x.mp4',
      rarity: AdminSiteAnimationRarity.common,
      context: 'voiceRoom',
      anchor: AdminSiteAnimationAnchor.seat,
      scale: 1.4,
      isActive: false,
    );
    final j = a.toApiJson();
    expect(j.containsKey('id'), isFalse);
    expect(j['category'], 'profile_frame');
    expect(j['type'], 'video');
    expect(j['membershipLevel'], 'basic');
    expect(j['rarity'], 'normal');
    expect(j['position'], 'seat');
    expect(j['anchor'], 'seat');
    expect(j['scale'], 'large');
    expect(j['status'], 'inactive');
    expect(j['contexts'], ['voice_room']);
  });

  test('sunucu yanıtı (type/status/membershipLevel/scale) doğru okunur', () {
    final a = AdminSiteAnimation.fromJson({
      'id': 'c1',
      'name': 'Kapı',
      'category': 'microphone',
      'type': 'svga',
      'membershipLevel': 'gold',
      'status': 'inactive',
      'scale': 'small',
      'position': 'top_center',
      'contexts': ['live_stream'],
      'metadata': {'description': 'açıklama'},
    });
    expect(a.category, AdminSiteAnimationCategory.mic);
    expect(a.animationType, 'svga');
    expect(a.membership, AdminSiteAnimationMembership.gold);
    expect(a.isActive, isFalse);
    expect(a.scale, lessThan(0.85));
    expect(a.anchor, AdminSiteAnimationAnchor.topCenter);
    expect(a.context, 'live_stream');
    expect(a.description, 'açıklama');
    // Gidiş-dönüş: yeniden gönderilince aynı değerler.
    final back = a.toApiJson();
    expect(back['membershipLevel'], 'gold');
    expect(back['scale'], 'small');
    expect(back['category'], 'microphone');
    expect(back['contexts'], ['live_stream']);
  });
}
