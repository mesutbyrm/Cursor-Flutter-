import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/agency/data/datasources/agency_management_datasource.dart';
import 'package:canlifal_social/features/agency/domain/entities/agency_management_models.dart';
import 'package:canlifal_social/features/agency/presentation/pages/agencies_page.dart';
import 'package:canlifal_social/features/agency/presentation/pages/agency_performance_pages.dart';
import 'package:canlifal_social/features/agency/presentation/pages/broadcaster_panel_page.dart';
import 'package:canlifal_social/features/agency/presentation/providers/agency_management_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _card({String id = 'a1', double? rate}) => {
      'id': id,
      'name': 'Yıldız Ajans',
      'level': 'gold',
      'verified': true,
      'featured': false,
      'activeMembers': 12,
      'verifiedHours30d': 340.5,
      'targetSuccessRate': rate,
      'closedTargets90d': rate == null ? 0 : 20,
      'activePromises': 1,
    };

Map<String, dynamic> _version({String id = 'v2', bool needs = true, int? prev = 1}) => {
      'id': id,
      'promiseId': 'p1',
      'title': 'Haftalık 20 saat',
      'version': 2,
      'body': 'Haftada 20 saat yayın yapan yayıncıya 5000 Jeton bonus.',
      'measurement': 'Yalnız video yayını sayılır.',
      'targetPeriod': 'weekly',
      'targetMinutes': 1200,
      'bonusJeton': 5000,
      'status': 'approved',
      'needsAcceptance': needs,
      'previouslyAcceptedVersion': prev,
    };

class _FakeDs extends AgencyManagementDataSource {
  _FakeDs() : super(Dio());

  final calls = <String>[];
  AgencyDetail detail = AgencyDetail.fromJson({
    'agency': _card(),
    'members': const [],
    'promises': [_version()],
    'relation': {'loggedIn': true, 'canApply': true},
  });
  BroadcasterPanel panel = BroadcasterPanel.fromJson({
    'membership': {
      'agency': {'id': 'a1', 'name': 'Yıldız Ajans'},
      'role': 'member',
      'joinedAt': '2026-09-01T10:00:00Z',
    },
    'totals': {
      'daily': {'verifiedMinutes': 30, 'activeDays': 1},
      'weekly': {'verifiedMinutes': 600, 'activeDays': 3},
      'monthly': {'verifiedMinutes': 2400, 'activeDays': 12},
    },
    'targets': [
      {'id': 't1', 'period': 'weekly', 'targetMinutes': 1200, 'verifiedMinutes': 600, 'activeDays': 3, 'remainingMinutes': 600, 'met': false, 'bonusJeton': 5000},
    ],
    'promises': [_version()],
    'rules': {'singleAgency': 'Tek ajans', 'leave': '3 gün', 'rights': 'Kayıtlar silinmez'},
  });

  @override
  Future<AgencyDetail> agencyDetail(String id) async => detail;

  @override
  Future<String> applyToAgency(String id, {String? message}) async {
    calls.add('apply:$id:${message ?? ''}');
    return 'Başvurunuz ajansa iletildi';
  }

  @override
  Future<BroadcasterPanel> broadcasterPanel() async => panel;

  @override
  Future<String> acceptPromise(String versionId) async {
    calls.add('accept:$versionId');
    return 'Kabul edildi';
  }

  @override
  Future<MemberPerformanceDetail> memberPerformance(String userId, {String period = 'weekly'}) async =>
      MemberPerformanceDetail.fromJson({
        'user': {'id': userId, 'name': 'Ayşe'},
        'summary': {'verifiedMinutes': 125, 'activeDays': 2, 'sessionCount': 3, 'interruptedCount': 1, 'daily': const []},
        'sessions': const [],
        'gifts': {'giftJeton': 900},
        'targets': const [],
        'accruals': [
          {'id': 'c1', 'userId': userId, 'period': 'weekly', 'targetMinutes': 600, 'verifiedMinutes': 700, 'met': true, 'bonusJeton': 300, 'status': 'earned'},
        ],
        'bonusTotals': {'earned': 300, 'paid': 0},
        'membershipHistory': const [],
        'moderation': const [],
      });

  @override
  Future<String> setTarget({required String userId, required String period, required int targetMinutes, int? minDays, int bonusJeton = 0}) async {
    calls.add('target:$userId:$period:$targetMinutes:$bonusJeton');
    return 'Hedef kaydedildi';
  }

  @override
  Future<String> payAccrual(String id) async {
    calls.add('pay:$id');
    return '300 Jeton bonus ödendi';
  }
}

Widget _wrap(_FakeDs ds, Widget child) => ProviderScope(
      overrides: [agencyManagementProvider.overrideWithValue(ds)],
      child: MaterialApp(home: child),
    );

Dio _dio(Map<String, (int, Object?)> routes, List<String> calls) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    calls.add('${o.method} ${o.path}${o.queryParameters.isEmpty ? '' : '?${o.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'}');
    final r = routes['${o.method} ${o.path}'] ?? (404, {'error': 'yok'});
    final res = Response<dynamic>(requestOptions: o, statusCode: r.$1, data: r.$2);
    if (r.$1 >= 400) return h.reject(DioException.badResponse(statusCode: r.$1, requestOptions: o, response: res));
    h.resolve(res);
  }));
  return dio;
}

void main() {
  group('modeller', () {
    test('dakika biçimi', () {
      expect(formatMinutes(0), '0 dk');
      expect(formatMinutes(45), '45 dk');
      expect(formatMinutes(120), '2 sa');
      expect(formatMinutes(125), '2 sa 5 dk');
    });

    test('hedef verisi yoksa başarı oranı null (sahte değer yok)', () {
      expect(AgencyCard.fromJson(_card()).targetSuccessRate, isNull);
      expect(AgencyCard.fromJson(_card(rate: 75)).targetSuccessRate, 75);
    });

    test('vaat hedef özeti', () {
      final v = PromiseVersionView.fromJson(_version());
      expect(v.targetSummary, 'Haftalık 20 sa · bonus 5000 Jeton');
    });
  });

  group('veri kaynağı', () {
    test('ajans listesi sıralama ile istenir ve ayrıştırılır', () async {
      final calls = <String>[];
      final ds = AgencyManagementDataSource(_dio({
        'GET /api/agencies': (200, {'success': true, 'data': {'agencies': [_card()]}}),
      }, calls));
      final list = await ds.agencies(sort: 'hours');
      expect(list.single.name, 'Yıldız Ajans');
      expect(calls.single, contains('sort=hours'));
    });

    test('sunucu hatası (409) mesajı aynen iletilir', () async {
      final ds = AgencyManagementDataSource(_dio({
        'POST /api/agencies/a1/join-request': (409, {'success': false, 'error': 'Önce mevcut ajansınızdan ayrılmalısınız'}),
      }, []));
      await expectLater(
        ds.applyToAgency('a1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Önce mevcut ajansınızdan ayrılmalısınız')),
      );
    });

    test('vaat kabulü açık onay (confirm:true) gönderir', () async {
      final calls = <String>[];
      final dio = _dio({'POST /api/agency/promises/v2/accept': (200, {'success': true, 'message': 'ok'})}, calls);
      Object? sent;
      dio.interceptors.insert(0, InterceptorsWrapper(onRequest: (o, h) {
        sent = o.data;
        h.next(o);
      }));
      await AgencyManagementDataSource(dio).acceptPromise('v2');
      expect(sent, {'confirm': true});
    });
  });

  testWidgets('ajans listesi: veri yoksa "Hedef verisi yok" yazar', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        agenciesListProvider.overrideWith((ref, args) async => [AgencyCard.fromJson(_card())]),
      ],
      child: const MaterialApp(home: AgenciesPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Yıldız Ajans'), findsOneWidget);
    expect(find.text('Hedef verisi yok'), findsOneWidget);
    expect(find.text('340.5 sa / 30 gün'), findsOneWidget);
  });

  testWidgets('ajans detayı: başvuru mesajla gönderilir', (tester) async {
    final ds = _FakeDs();
    await tester.pumpWidget(_wrap(ds, const AgencyDetailPage(agencyId: 'a1')));
    await tester.pumpAndSettle();
    expect(find.text('Haftalık 20 saat'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('agency-detail-apply')));
    await tester.tap(find.byKey(const Key('agency-detail-apply')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('agency-apply-message')), 'Merhaba');
    await tester.tap(find.text('Gönder'));
    await tester.pumpAndSettle();
    expect(ds.calls, ['apply:a1:Merhaba']);
    expect(find.text('Başvurunuz ajansa iletildi'), findsOneWidget);
  });

  testWidgets('yayıncı paneli: vaat açık onayla kabul edilir, hedef ilerlemesi görünür', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ds = _FakeDs();
    await tester.pumpWidget(_wrap(ds, const BroadcasterPanelPage()));
    await tester.pumpAndSettle();
    expect(find.text('1 vaat onayınızı bekliyor'), findsOneWidget);
    expect(find.textContaining('Kalan: 10 sa'), findsOneWidget);
    expect(find.text('Sürüm 1 kabulünüz kayıtlı; şartlar güncellendi.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('promise-accept-v2')));
    await tester.pumpAndSettle();
    expect(ds.calls, isEmpty, reason: 'onaysız istek gitmemeli');
    await tester.tap(find.byKey(const Key('promise-accept-confirm')));
    await tester.pumpAndSettle();
    expect(ds.calls, ['accept:v2']);
  });

  testWidgets('yayıncı paneli: ajansı olmayan kullanıcıya keşif önerilir', (tester) async {
    final ds = _FakeDs()..panel = BroadcasterPanel.fromJson({'membership': null, 'rules': const {}});
    await tester.pumpWidget(_wrap(ds, const BroadcasterPanelPage()));
    await tester.pumpAndSettle();
    expect(find.text('Bir ajansa bağlı değilsiniz.'), findsOneWidget);
    expect(find.byKey(const Key('broadcaster-find-agency')), findsOneWidget);
  });

  testWidgets('yayıncı ayrıntısı: hedef saat → dakika, hak ediş ödemesi onayla', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ds = _FakeDs();
    await tester.pumpWidget(_wrap(ds, const AgencyMemberPerformancePage(userId: 'u1')));
    await tester.pumpAndSettle();
    expect(find.text('2 sa 5 dk'), findsOneWidget);

    await tester.tap(find.byKey(const Key('member-set-target')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('target-hours')), '12,5');
    await tester.tap(find.byKey(const Key('target-save')));
    await tester.pumpAndSettle();
    expect(ds.calls, ['target:u1:weekly:750:0']);

    await tester.tap(find.byKey(const Key('accrual-pay-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accrual-pay-confirm')));
    await tester.pumpAndSettle();
    expect(ds.calls.last, 'pay:c1');
  });
}
