import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_content_section.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Profil içerik sekmeleri: 4 ana sekme + ⋮ menüsü, dar ekran + büyük yazıda taşmaz',
      (tester) async {
    tester.view.physicalSize = const Size(640, 1136); // 320x568 dp
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSocialPostsProvider('u1').overrideWith((ref) async => <PostEntity>[]),
          socialStoryRingsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: c!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: ProfileContentSection(userId: 'u1')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    for (final t in ['Gönderiler', 'Videolar', 'Hikâyeler', 'Fal Aktiviteleri']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Diğer içerikler ⋮ menüsünde korunur (kayıp yok).
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    for (final t in ['Beğeniler', 'Kaydedilen', 'Canlı Yayınlarım', 'İzlediklerim', 'Favoriler', 'Taslaklar']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Henüz gönderi yok'), findsOneWidget);

    await tester.tap(find.text('Hikâyeler'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Aktif hikâyen yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
