import 'package:canlifal_social/core/site_animation/domain/site_animation_command.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:canlifal_social/core/site_animation/presentation/widgets/site_animation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('site animation card completes enter/hold/exit sequence', (tester) async {
    var finished = false;
    const command = SiteAnimationCommand(
      eventId: 'test-card',
      roomId: 'room',
      type: SiteAnimationType.memberJoined,
      tier: SiteAnimationTier.gold,
      userId: 'u1',
      userName: 'Ayşe Yıldız',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SiteAnimationCard(
                command: command,
                onFinished: () => finished = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(finished, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 900));
    expect(finished, isTrue);
  });
}
