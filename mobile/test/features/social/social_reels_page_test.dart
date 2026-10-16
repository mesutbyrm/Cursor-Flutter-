import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/presentation/pages/social_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_reels_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'GirLive Sosyal: üst bar Canlı · Keşfet · Takip Ettiğin, tam ekran tek paylaşım',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(PersistCookieJar()),
          authControllerProvider.overrideWith(
            () => _FakeAuth(const UserEntity(
              id: 'u1',
              username: 'admin',
              displayName: 'Admin',
            )),
          ),
          socialReelsProvider.overrideWith(_StubReels.new),
        ],
        child: const MaterialApp(home: SocialPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Canlı'), findsOneWidget);
    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Takip Ettiğin'), findsOneWidget);
    // Yazı paylaşımı ekranda tek sayfa olarak; ikincisi kaydırınca gelir.
    expect(find.text('Merhaba GirLive'), findsOneWidget);
    expect(find.text('İkinci paylaşım'), findsNothing);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _StubReels extends SocialReelsNotifier {
  @override
  Future<List<PostEntity>> build(String feed) async => [
        PostEntity(
          id: 'p1',
          author: const UserEntity(id: 'u2', username: 'ayse', displayName: 'Ayşe'),
          caption: 'Merhaba GirLive',
          likesCount: 3,
          commentsCount: 1,
        ),
        PostEntity(
          id: 'p2',
          author: const UserEntity(id: 'u3', username: 'ali', displayName: 'Ali'),
          caption: 'İkinci paylaşım',
        ),
      ];
}
