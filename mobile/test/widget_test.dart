import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/app/app.dart';
import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/domain/repositories/auth_repository.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> currentUser() async => null;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('Uygulama açılır', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(CookieJar()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const CanlifalApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
