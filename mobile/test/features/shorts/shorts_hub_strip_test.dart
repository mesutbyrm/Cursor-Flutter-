import 'package:canlifal_social/features/home/domain/entities/home_trend_video_entity.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/shorts/presentation/widgets/shorts_hub_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShortsHubStrip hides when feed is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTrendVideosProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ShortsHubStrip()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kısa Videolar'), findsNothing);
  });

  testWidgets('ShortsHubStrip shows videos when data exists', (tester) async {
    const videos = [
      HomeTrendVideoEntity(
        id: 'v1',
        title: 'Test video',
        channelName: 'user1',
        viewCount: 1200,
        likesCount: 45,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTrendVideosProvider.overrideWith((ref) async => videos),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ShortsHubStrip()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kısa Videolar'), findsOneWidget);
    expect(find.text('1.2K'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });
}
