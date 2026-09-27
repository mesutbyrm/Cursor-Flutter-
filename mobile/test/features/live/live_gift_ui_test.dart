import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:canlifal_social/features/gifts/domain/gift_staff_finance_mode.dart';
import 'package:canlifal_social/features/gifts/domain/lucky_gift_entities.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/gift_providers.dart';
import 'package:canlifal_social/features/gifts/presentation/widgets/premium_gift_panel.dart';
import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/live/data/services/live_gift_realtime_service.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_type.dart';
import 'package:canlifal_social/features/live/domain/entities/live_stream_entity.dart';
import 'package:canlifal_social/features/live/presentation/gifts/live_gift_controller.dart';
import 'package:canlifal_social/features/live/presentation/gifts/providers/live_gift_providers.dart';
import 'package:canlifal_social/features/live/presentation/widgets/live_gift_sheet.dart';
import 'package:canlifal_social/features/live/presentation/widgets/live_stream_list_tile.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

class _Remote implements LiveGiftsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Realtime implements LiveGiftRealtimeService {
  final _c = StreamController<LiveGiftEvent>.broadcast();
  @override
  Stream<LiveGiftEvent> get events => _c.stream;
  @override
  void start(String streamId) {}
  @override
  void stop() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

/// PK hediye seçici için: istek [gate] tamamlanana kadar bekler.
class _SlowRemote implements LiveGiftsRemoteDataSource {
  final gate = Completer<void>();
  var calls = 0;

  @override
  Future<LiveGiftSendResult> sendGift({
    required String streamId,
    required String giftTypeId,
    required String senderName,
    required String receiverName,
    required String giftName,
    required int unitPrice,
    int quantity = 1,
    String? senderId,
    String? toUserId,
    String? pkMatchId,
    bool isLucky = false,
    GiftStaffFinanceMode? staffFinanceMode,
  }) async {
    calls++;
    await gate.future;
    return const LiveGiftSendResult();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() async => WalletBalances.empty;
  @override
  Future<WalletBalances> refresh({bool force = false}) async =>
      WalletBalances.empty;
}

class _Ctrl extends LiveGiftController {
  _Ctrl() : super(remote: _Remote(), realtime: _Realtime());

  final sent = <(String, int)>[];

  @override
  Future<LuckyGiftSpinResult?> send({
    required LiveVideoGiftType gift,
    required String senderName,
    String? senderId,
    int quantity = 1,
    String? toUserId,
    String? pkMatchId,
    GiftStaffFinanceMode? staffFinanceMode,
  }) async {
    sent.add((gift.name, quantity));
    return null;
  }
}

const _catalog = [
  GiftEntity(id: 'g1', name: 'Gül', price: 10),
  GiftEntity(id: 'g2', name: 'Kalp', price: 20),
  GiftEntity(id: 'g3', name: 'Kristal Fal', price: 50),
];

Future<_Ctrl> _pumpPanel(
  WidgetTester tester, {
  int? balance,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ctrl = _Ctrl();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        liveGiftCatalogProvider.overrideWith((ref) async => _catalog),
        streamGiftLeaderboardProvider.overrideWith((ref, id) async => const []),
        coinBalanceProvider.overrideWithValue(balance),
        walletBalancesProvider.overrideWith(_Wallet.new),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PremiumGiftPanel(
              controller: ctrl,
              streamId: 's1',
              senderName: 'Ben',
              onClose: () {},
            ),
          ),
        ),
      ),
    ),
  );
  // Panel alttan kayarak açılır (340 ms); dokunuşlar ekranda olsun.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return ctrl;
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.text('Gönder'));
  await tester.pump();
}

void main() {
  group('PremiumGiftPanel', () {
    testWidgets('bakiye bilinmiyorsa "0" değil "—" gösterir', (tester) async {
      await _pumpPanel(tester);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('gerçek bakiye gösterilir', (tester) async {
      await _pumpPanel(tester, balance: 1250);
      expect(find.text('1250'), findsOneWidget);
    });

    testWidgets('kategori değişince görünmeyen hediye gönderilmez', (
      tester,
    ) async {
      final ctrl = await _pumpPanel(tester, balance: 100);
      await tester.tap(find.text('Kalp'));
      await tester.pump();
      await tester.tap(find.text('Fal'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Kalp'), findsNothing);
      await _tapSend(tester);
      expect(ctrl.sent.single.$1, 'Kristal Fal');
      await _dispose(tester);
    });

    testWidgets('boş kategoride gönder pasif ve bilgi verilir', (tester) async {
      final ctrl = await _pumpPanel(tester, balance: 100);
      await tester.tap(find.text('Kalp'));
      await tester.pump();
      await tester.tap(find.text('VIP'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Bu kategoride hediye yok'), findsOneWidget);
      await _tapSend(tester);
      expect(ctrl.sent, isEmpty);
    });

    testWidgets('gönder butonu seçili hediye × adet toplamını gösterir', (
      tester,
    ) async {
      final ctrl = await _pumpPanel(tester, balance: 100);
      await tester.tap(find.text('Kalp'));
      await tester.pump();
      await tester.tap(find.text('x5'));
      await tester.pump();
      expect(find.text('100'), findsNWidgets(2)); // bakiye + toplam
      await _tapSend(tester);
      expect(ctrl.sent.single, ('Kalp', 5));
      await _dispose(tester);
    });

    testWidgets('açık temada başlık koyu panelde okunur', (tester) async {
      await _pumpPanel(tester, theme: AppTheme.light());
      final ctx = tester.element(find.text('Hediye Gönder'));
      expect(Theme.of(ctx).brightness, Brightness.dark);
    });
  });

  group('LiveStreamListTile', () {
    Future<void> pump(WidgetTester tester, LiveStreamEntity s) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: LiveStreamListTile(stream: s, onTap: null),
            ),
          ),
        );

    testWidgets('bitmiş yayında "0 izleyici" yerine "Yayında değil"', (
      tester,
    ) async {
      await pump(
        tester,
        const LiveStreamEntity(
          id: 's1',
          title: 'Akşam sohbeti',
          streamerName: 'Ece',
          isLive: false,
        ),
      );
      expect(find.textContaining('Yayında değil'), findsOneWidget);
      expect(find.textContaining('izleyici'), findsNothing);
    });

    testWidgets('canlı yayında izleyici sayısı kısaltılır', (tester) async {
      await pump(
        tester,
        const LiveStreamEntity(
          id: 's1',
          title: 'Akşam sohbeti',
          streamerName: 'Ece',
          isLive: true,
          viewerCount: 12500,
        ),
      );
      expect(find.text('Ece · 12.5K izleyici'), findsOneWidget);
    });
  });

  testWidgets('PK hediye seçici: hızlı iki dokunuş tek hediye gönderir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final remote = _SlowRemote();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_NoAuth.new),
          walletBalancesProvider.overrideWith(_Wallet.new),
          coinBalanceProvider.overrideWithValue(300),
          liveStreamGiftCatalogProvider.overrideWith((ref) async => _catalog),
          liveGiftsRemoteProvider.overrideWithValue(remote),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () =>
                    showLiveGiftPicker(context, ref, streamId: 's1'),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('300'), findsOneWidget, reason: 'gerçek bakiye');
    await tester.tap(find.text('Gül'));
    await tester.pump();
    await tester.tap(find.text('Gül'), warnIfMissed: false);
    await tester.pump();
    expect(remote.calls, 1);

    remote.gate.complete();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
