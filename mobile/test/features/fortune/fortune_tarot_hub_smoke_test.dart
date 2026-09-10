import 'package:canlifal_social/core/economy/domain/economy_wallet_snapshot.dart';
import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';
import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/fortune/domain/entities/fortune_display_entry.dart';
import 'package:canlifal_social/features/fortune/domain/entities/user_fortune_entity.dart';
import 'package:canlifal_social/features/fortune/presentation/pages/fortune_tarot_hub_page.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_api_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_birth_profile_provider.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_hub_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_types_display_provider.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hub shows core sections without build exceptions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final errors = <Object>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.exception);
      prev?.call(d);
    };

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
          economyWalletProvider.overrideWith(
            (ref) async => const EconomyWalletSnapshot(cfc: 100, jeton: 50),
          ),
          fortuneHistoryProvider.overrideWith(_EmptyHistory.new),
          fortuneBirthProfileProvider.overrideWith((ref) async => null),
          fortuneDailyInsightsProvider.overrideWith(
            (ref) async => FortuneDailyInsights.fallback(),
          ),
          homeFortuneCardsProvider.overrideWith((ref) async => []),
          homeFortuneRequestTypesProvider.overrideWith((ref) async => []),
          homeTrendVideosProvider.overrideWith((ref) async => []),
          homeOnlinePsychicsProvider.overrideWith((ref) async => []),
          fortuneTypesDisplayProvider.overrideWith(
            (ref) async => const [
              FortuneDisplayEntry(slug: 'tarot', title: 'Tarot'),
            ],
          ),
          socialNotifierProvider.overrideWith(_StubSocial.new),
        ],
        child: const MaterialApp(home: FortuneTarotHubPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('POPÜLER FAL TÜRLERİ'),
      400,
      scrollable: scrollable,
    );
    await tester.pump();

    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(find.textContaining('POPÜLER FAL TÜRLERİ'), findsOneWidget);
    expect(
      find.byElementPredicate((e) {
        final w = e.widget;
        if (w is! Text) return false;
        final data = w.data ?? w.textSpan?.toPlainText() ?? '';
        return data == 'FAL TÜRLERİ';
      }),
      findsOneWidget,
    );
    expect(find.text('Bir bölüm yüklenemedi'), findsNothing);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _EmptyHistory extends FortuneHistoryNotifier {
  @override
  Future<List<UserFortuneEntity>> build() async => [];
}

class _StubSocial extends SocialNotifier {
  @override
  Future<List<PostEntity>> build() async => [];
}
