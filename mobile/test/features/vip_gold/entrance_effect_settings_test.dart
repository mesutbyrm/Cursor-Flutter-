import 'package:canlifal_social/features/vip_gold/domain/entrance_effect_settings.dart';
import 'package:canlifal_social/features/vip_gold/domain/entrance_visual_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EntranceEffectSettings round-trips visualStyle', () {
    const settings = EntranceEffectSettings(
      visualStyle: EntranceVisualStyle.centerFullscreen,
    );
    final json = settings.toJson();
    expect(json['visualStyle'], 'centerFullscreen');
    final restored = EntranceEffectSettings.fromJson(json);
    expect(restored.visualStyle, EntranceVisualStyle.centerFullscreen);
  });

  test('defaults to top team pass', () {
    expect(
      const EntranceEffectSettings().visualStyle,
      EntranceVisualStyle.topTeamPass,
    );
  });
}
