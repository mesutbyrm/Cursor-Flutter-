import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/presentation/pages/social_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SocialPage has Paylaş and no Hikayen rail', (tester) async {
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
          socialNotifierProvider.overrideWith(_StubSocial.new),
          socialStoryRingsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: SocialPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Paylaş'), findsOneWidget);
    expect(find.text('Hikayen'), findsNothing);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _StubSocial extends SocialNotifier {
  @override
  Future<List<PostEntity>> build() async => [];
}
