import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/common_benefits.dart';

void main() {
  group('MembershipCommonBenefits', () {
    testWidgets('API features 2 öğe — taşma yok', (tester) async {
      const highlights = [
        MembershipFeatureHighlightEntity(
          id: 'badge',
          title: 'Özel Rozet',
        ),
        MembershipFeatureHighlightEntity(
          id: 'support',
          title: 'Öncelikli Destek',
          subtitle: '7/24',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MembershipCommonBenefits(highlights: highlights),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Üyelik Avantajları'), findsOneWidget);
      expect(find.text('Özel Rozet'), findsOneWidget);
      expect(find.text('Öncelikli Destek'), findsOneWidget);
    });

    testWidgets('API features 5 öğe — hepsi görünür', (tester) async {
      final highlights = [
        for (var i = 0; i < 5; i++)
          MembershipFeatureHighlightEntity(
            id: 'f$i',
            title: 'Avantaj $i',
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembershipCommonBenefits(highlights: highlights),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        expect(find.text('Avantaj $i'), findsOneWidget);
      }
    });
  });
}
