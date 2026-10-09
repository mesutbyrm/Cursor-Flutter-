import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/live/presentation/providers/discover_voice_rooms.dart';
import 'package:canlifal_social/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:canlifal_social/features/social/data/datasources/social_discovery_remote_datasource.dart';
import 'package:canlifal_social/features/social/domain/entities/social_discovery_feed.dart';
import 'package:canlifal_social/features/social/domain/entities/social_discovery_user.dart';
import 'package:canlifal_social/features/social/domain/entities/user_location_settings.dart';
import 'package:canlifal_social/features/social/presentation/pages/tanis_kaynas_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_discovery_providers.dart';

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

/// Ağ çağrısı yapmayan sahte veri kaynağı (yalnızca testte).
class _FakeRemote extends SocialDiscoveryRemoteDataSource {
  _FakeRemote({this.users = const [], this.fail = false}) : super(Dio());

  final List<SocialDiscoveryUser> users;
  final bool fail;

  @override
  Future<SocialDiscoveryFeed> fetchDiscovery({
    int page = 1,
    int limit = 20,
    int? minAge,
    int? maxAge,
    String? city,
    bool? onlineOnly,
    String? gender,
    String? membership,
    String? interest,
    String? filter,
  }) async {
    if (fail) throw Exception('ağ hatası');
    return SocialDiscoveryFeed(users: users, total: users.length);
  }

  @override
  Future<Set<String>> fetchSentActionTargetIds() async => {};

  @override
  Future<List<SocialDiscoveryUser>> fetchMatches() async => const [];

  @override
  Future<List<SocialDiscoveryUser>> fetchIncomingLikes() async => users;

  @override
  Future<List<SocialDiscoveryUser>> fetchSentLikes() async => const [];

  @override
  Future<UserLocationSettings> fetchLocationSettings() async =>
      const UserLocationSettings();
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required _FakeRemote remote,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const TanisKaynasPage())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_NoAuth.new),
        socialDiscoveryRemoteProvider.overrideWithValue(remote),
        voiceRoomsProvider.overrideWith(
          (ref) async => const [
            VoiceRoomEntity(
              id: 'r1',
              slug: 'r1',
              nameTr: 'Gece Muhabbeti',
              onlineCount: 12,
              userCount: 12,
            ),
          ],
        ),
        notificationsUnreadCountProvider.overrideWithValue(3),
      ],
      child: MaterialApp.router(
        theme: theme ?? ThemeData.dark(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

SocialDiscoveryUser _u(String id) => SocialDiscoveryUser.fromJson({
      'id': id,
      'name': 'Ayşe $id',
      'age': 26,
      'city': 'İstanbul',
      'bio': 'Güzel sohbetler',
      'hobbies': ['Müzik', 'Film'],
      'commonHobbies': ['Müzik'],
      'matchPercent': 50,
      'distance': {'band': '1-5', 'text': '2 km'},
      'lastActive': DateTime.now().toUtc().toIso8601String(),
    });

void main() {
  for (final width in [360.0, 430.0]) {
    testWidgets('$width px: sayfa gerçek verilerle taşmadan açılır',
        (tester) async {
      await _pump(
        tester,
        width: width,
        remote: _FakeRemote(users: [_u('1'), _u('2')]),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Şu An Çevrimiçi'), findsOneWidget);
      expect(find.text('2 kişi çevrimiçi'), findsOneWidget);
      expect(find.text('Tanış'), findsOneWidget);
      expect(find.text('Gece Muhabbeti'), findsOneWidget);
      expect(find.text('Odaya Katıl'), findsOneWidget);
      expect(find.text('Seninle Aynı Şeyleri Sevenler'), findsOneWidget);
      // Yeni bölümler: etkinlik sayaçları, buz kırıcı, hızlı erişim.
      expect(find.text('Seni beğenen'), findsOneWidget);
      expect(find.text('Günün buz kırıcı sorusu'), findsOneWidget);
      expect(find.text('Burç Uyumu'), findsOneWidget);
      expect(find.text('Hikâye Paylaş'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('seni beğenen sayısı gerçek veriden gelir', (tester) async {
    await _pump(
      tester,
      width: 400,
      remote: _FakeRemote(users: [_u('1'), _u('2')]),
    );
    final tile = find.byKey(const Key('tk-stat-incoming'));
    expect(
      find.descendant(of: tile, matching: find.text('2')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('açık tema da çizilir', (tester) async {
    await _pump(
      tester,
      width: 390,
      remote: _FakeRemote(users: [_u('1')]),
      theme: ThemeData.light(),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Tanış'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kimse yoksa boş durum', (tester) async {
    await _pump(tester, width: 390, remote: _FakeRemote());
    expect(find.text('Henüz sana uygun biri bulunamadı.'), findsOneWidget);
    expect(find.text('Filtreleri Düzenle'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hata durumunda tekrar dene', (tester) async {
    await _pump(tester, width: 390, remote: _FakeRemote(fail: true));
    expect(find.text('Bir şeyler ters gitti.'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
