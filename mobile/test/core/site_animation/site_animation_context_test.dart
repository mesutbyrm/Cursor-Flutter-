import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/site_animation/presentation/widgets/site_animation_context_host.dart';

void main() {
  test('SiteAnimationContext overlay ids are stable', () {
    expect(SiteAnimationContext.liveStream.overlayId, 'ctx_live');
    expect(SiteAnimationContext.gift.overlayId, 'ctx_gift');
    expect(SiteAnimationContext.game.overlayId, 'ctx_game');
    expect(SiteAnimationContext.falTarot.overlayId, 'ctx_fal_tarot');
  });
}
