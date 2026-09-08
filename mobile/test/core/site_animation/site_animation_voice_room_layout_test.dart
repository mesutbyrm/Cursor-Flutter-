import 'package:canlifal_social/core/site_animation/presentation/utils/site_animation_voice_room_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice room layout host seat is left of grid seats', () {
    const width = 390.0;
    final host = SiteAnimationVoiceRoomLayout.seatCenter(width, 1, stageTop: 76);
    final seat3 = SiteAnimationVoiceRoomLayout.seatCenter(width, 3, stageTop: 76);
    expect(host.dx, lessThan(seat3.dx));
  });

  test('entrance panel fits below header', () {
    const size = Size(390, 844);
    final rect = SiteAnimationVoiceRoomLayout.entrancePanelRect(
      size,
      stageTop: SiteAnimationVoiceRoomLayout.headerHeight,
    );
    expect(rect.top, greaterThan(SiteAnimationVoiceRoomLayout.headerHeight));
    expect(rect.width, inInclusiveRange(280, 360));
    expect(rect.height, inInclusiveRange(70, 110));
  });
}
