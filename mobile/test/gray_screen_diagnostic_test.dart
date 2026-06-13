import 'dart:async';

import 'package:canlifal_social/app/app.dart';
import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gri ekran teşhisi — exception + ModalBarrier ağaç taraması.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final capturedErrors = <FlutterErrorDetails>[];
  FlutterErrorDetails? originalOnErrorDetails;

  setUp(() {
    capturedErrors.clear();
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      capturedErrors.add(details);
      debugPrint('CAPTURED_ERROR: ${details.exception}');
      debugPrint('CAPTURED_STACK: ${details.stack}');
      original?.call(details);
    };
  });

  testWidgets('soğuk açılış oturumlu — exception ve barrier taraması', (tester) async {
    const user = UserEntity(
      id: 'u1',
      username: 'testuser',
      displayName: 'Test',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(PersistCookieJar()),
          authControllerProvider.overrideWith(() => _FakeAuthController(user)),
        ],
        child: const CanlifalApp(),
      ),
    );

    await _pumpAndScan(tester, capturedErrors, label: 'authed-cold-start');
  });

  testWidgets('giriş geçişi — exception ve barrier taraması', (tester) async {
    final controller = _TransitionAuthController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(PersistCookieJar()),
          authControllerProvider.overrideWith(() => controller),
        ],
        child: const CanlifalApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _scan(tester, capturedErrors, label: 'before-login');

    controller.completeLogin(
      const UserEntity(id: 'u1', username: 'testuser', displayName: 'Test'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await _pumpAndScan(tester, capturedErrors, label: 'after-login');
  });
}

Future<void> _pumpAndScan(
  WidgetTester tester,
  List<FlutterErrorDetails> errors, {
  required String label,
}) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
  await _scan(tester, errors, label: label);
}

Future<void> _scan(
  WidgetTester tester,
  List<FlutterErrorDetails> errors, {
  required String label,
}) async {
  final barriers = <Element>[];
  final absorb = <Element>[];
  void visit(Element element) {
    final w = element.widget;
    if (w is ModalBarrier) barriers.add(element);
    if (w is AbsorbPointer && w.absorbing) absorb.add(element);
    element.visitChildren(visit);
  }
  tester.binding.rootElement?.visitChildren(visit);

  debugPrint('=== SCAN $label ===');
  debugPrint('Exceptions: ${errors.length}');
  for (final e in errors) {
    debugPrint('EX: ${e.exception}');
    debugPrint('AT: ${e.stack}');
  }
  debugPrint('ModalBarrier count: ${barriers.length}');
  for (final b in barriers) {
    final w = b.widget as ModalBarrier;
    debugPrint('  barrier color=${w.color}');
  }
  debugPrint('AbsorbPointer count: ${absorb.length}');

  if (errors.isNotEmpty) {
    fail(
      errors.map((e) => '${e.exception}\n${e.stack}').join('\n---\n'),
    );
  }
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _TransitionAuthController extends AuthController {
  final _completer = Completer<UserEntity?>();

  void completeLogin(UserEntity user) {
    if (!_completer.isCompleted) {
      _completer.complete(user);
    }
    state = AsyncValue.data(user);
  }

  @override
  Future<UserEntity?> build() async {
    return _completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }
}
