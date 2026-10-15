import 'package:canlifal_social/features/cosmetics/data/cosmetics_equip_remote_datasource.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_effect_kind.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_item.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_name_style.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sitedeki cssPreset biçimleri ayrıştırılır', () {
    final gradient = CosmeticNameStyle.parse(
      '{"backgroundImage":"linear-gradient(90deg,#FDE68A,#F59E0B,#B45309)",'
      '"WebkitBackgroundClip":"text","color":"transparent","fontWeight":800}',
    )!;
    expect(gradient.mode, CosmeticNameStyleMode.gradient);
    expect(gradient.colors, const [
      Color(0xFFFDE68A),
      Color(0xFFF59E0B),
      Color(0xFFB45309),
    ]);

    final shine = CosmeticNameStyle.parse({
      'backgroundImage': 'linear-gradient(110deg,#6B7280 20%,#E5E7EB 45%,#9CA3AF 60%,#6B7280 80%)',
      'animation': 'cfShine 2.8s linear infinite',
    })!;
    expect(shine.mode, CosmeticNameStyleMode.shine);
    expect(shine.colors.length, 4);
    expect(shine.periodMs, 2800);

    final glow = CosmeticNameStyle.parse(
      {'color': '#CFFAFE', 'textShadow': '0 0 6px #22D3EE, 0 0 14px #22D3EE'},
    )!;
    expect(glow.mode, CosmeticNameStyleMode.glow);
    expect(glow.accent, const Color(0xFF22D3EE));

    final outline = CosmeticNameStyle.parse(
      {'color': '#E9D5FF', 'WebkitTextStroke': '1px #6D28D9'},
    )!;
    expect(outline.mode, CosmeticNameStyleMode.outline);
    expect(outline.accent, const Color(0xFF6D28D9));

    final solid = CosmeticNameStyle.parse({'color': '#A1A1AA', 'fontWeight': 700})!;
    expect(solid.mode, CosmeticNameStyleMode.solid);

    expect(CosmeticNameStyle.parse(null), isNull);
    expect(CosmeticNameStyle.parse('bozuk'), isNull);
  });

  test('backend isim efekti cssPreset taşır; çerçeve görseli imageOverlay olur', () {
    final name = CosmeticsEquipRemoteDataSource.itemFromBackend(
      CosmeticSlot.nameEffect,
      {
        'key': 'gold_glow',
        'name': 'Altın Parlama',
        'tier': 'gold',
        'cssPreset': '{"color":"#FDE68A","textShadow":"0 0 6px #F59E0B"}',
      },
    );
    expect(name.id, 'gold_glow');
    expect(name.nameStyle?.mode, CosmeticNameStyleMode.glow);

    final frame = CosmeticItem.fromJson({
      'id': 'frame-lion-1',
      'name': 'Aslan',
      'imageUrl': '/frames/lion-1.png',
      'tier': 'gold',
    });
    expect(frame.effectKind, CosmeticEffectKind.imageOverlay);
    expect(frame.imageUrl, '/frames/lion-1.png');

    final fx = CosmeticsEquipRemoteDataSource.itemFromBackend(
      CosmeticSlot.profileEffect,
      {'id': 'aurora', 'key': 'aurora', 'name': 'Kuzey Işıkları', 'tier': 'diamond'},
    );
    expect(fx.effectKind, CosmeticEffectKind.particleGalaxy);
  });
}
