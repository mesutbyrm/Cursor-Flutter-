import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:canlifal_social/core/site_animation/presentation/widgets/site_animation_exit_card.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exit card renders tier subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SiteAnimationExitCard(
            command: SiteAnimationCommand(
              eventId: 't',
              roomId: 'r',
              type: SiteAnimationType.memberLeft,
              tier: SiteAnimationTier.gold,
              userId: 'u',
              userName: 'Ayşe',
              animationId: 'anim_exit_gold',
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Tekrar bekleriz'), findsOneWidget);
  });
}
