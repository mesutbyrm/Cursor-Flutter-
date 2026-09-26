import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/data/datasources/social_remote_datasource.dart';
import 'package:canlifal_social/features/social/domain/repositories/social_repository.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:canlifal_social/features/social/presentation/widgets/instagram/double_tap_heart.dart';
import 'package:canlifal_social/features/social/presentation/widgets/instagram/social_instagram_post_card.dart';

class _FakeRepo implements SocialRepository {
  var likeCalls = 0;

  @override
  Future<({bool liked, int likesCount})> toggleLike(String postId) async {
    likeCalls++;
    return (liked: true, likesCount: 6);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuietRemote extends SocialRemoteDataSource {
  _QuietRemote() : super(Dio());

  @override
  Future<void> registerPostView(String postId) async {}
}

class _StubSocial extends SocialNotifier {
  @override
  Future<List<PostEntity>> build() async => [];
}

const _author = UserEntity(
  id: 'author',
  username: 'yazar',
  displayName: 'Yazar',
);

PostEntity post({
  bool liked = false,
  String? media = 'https://cdn.test/p.jpg',
}) => PostEntity(
  id: 'p1',
  author: _author,
  caption: 'Merhaba',
  mediaUrl: media,
  likesCount: 5,
  likedByMe: liked,
);

void main() {
  late _FakeRepo repo;

  Widget host(PostEntity p, {ThemeData? theme}) => ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('me'),
      socialRepositoryProvider.overrideWithValue(repo),
      socialRemoteProvider.overrideWithValue(_QuietRemote()),
      socialNotifierProvider.overrideWith(_StubSocial.new),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SocialInstagramPostCard(post: p, openProfileOnTap: false),
        ),
      ),
    ),
  );

  setUp(() => repo = _FakeRepo());

  Future<void> doubleTapMedia(WidgetTester tester) async {
    final media = find.ancestor(
      of: find.byType(DoubleTapHeart),
      matching: find.byType(AspectRatio),
    );
    final point = tester.getTopLeft(media) + const Offset(40, 40);
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('görsele çift dokunuş beğenir ve kalp gösterir', (tester) async {
    await tester.pumpWidget(host(post()));
    await tester.pump();

    await doubleTapMedia(tester);
    expect(repo.likeCalls, 1);
    final heart = find.descendant(
      of: find.byType(DoubleTapHeart),
      matching: find.byIcon(Icons.favorite_rounded),
    );
    expect(heart, findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(heart, findsNothing, reason: 'animasyon bitince kalp kaybolur');
  });

  testWidgets('beğenilmiş gönderide çift dokunuş beğeniyi geri almaz', (
    tester,
  ) async {
    await tester.pumpWidget(host(post(liked: true)));
    await tester.pump();

    await doubleTapMedia(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(repo.likeCalls, 0);
  });

  testWidgets(
    'seçenek menüsü gerçek eylemleri içerir (kendi gönderisi değil)',
    (tester) async {
      await tester.pumpWidget(host(post()));
      await tester.pump();
      await tester.tap(find.byTooltip('Gönderi seçenekleri'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Profili gör'), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
      expect(find.text('Sil'), findsNothing);
    },
  );

  testWidgets('açık temada metin-only gönderi metni okunur (koyu kutu yok)', (
    tester,
  ) async {
    await tester.pumpWidget(host(post(media: null), theme: AppTheme.light()));
    await tester.pump();
    final box = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration);
    final gradients = box
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .expand((g) => g.colors);
    for (final c in gradients) {
      expect(
        c.computeLuminance(),
        greaterThan(0.5),
        reason: 'açık temada metin kutusu açık renkte olmalı',
      );
    }
  });
}
