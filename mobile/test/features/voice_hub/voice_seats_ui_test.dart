import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/data/mappers/voice_rooms_discover_mapper.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';
import 'package:canlifal_social/features/voice_hub/domain/repositories/voice_rooms_discover_repository.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_seat_gift_totals_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium_2026/voice_mic_seat.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium_2026/voice_seat_avatar_frame.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium_2026/voice_web_owner_stage.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_rooms_ui/voice_rooms_ui.dart';

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

class _FakeLive extends VoiceRoomLiveController {
  _FakeLive(this.s);
  final VoiceRoomLiveState s;
  @override
  VoiceRoomLiveState build(String arg) => s;
}

class _Gifts extends VoiceSeatGiftTotals {
  _Gifts(this.m);
  final Map<String, SeatGiftAggregate> m;
  @override
  Map<String, SeatGiftAggregate> build() => m;
}

const _room = VoiceRoomEntity(id: 'r1', slug: 'r1', nameTr: 'Oda');

List<Override> _overrides({
  VoiceRoomLiveState live = const VoiceRoomLiveState(loading: false),
  Map<String, SeatGiftAggregate> gifts = const {},
}) => [
  authControllerProvider.overrideWith(_NoAuth.new),
  voiceRoomLiveProvider.overrideWith(() => _FakeLive(live)),
  voiceSeatGiftTotalsProvider.overrideWith(() => _Gifts(gifts)),
];

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides.isEmpty ? _overrides() : overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
      ),
    );

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('Koltuk sahnesi', () {
    const names = [
      'Abdurrahman Yıldırımoğlu',
      'Ece',
      'Zeynep Karadenizli',
      'Mert',
      'Selin Kayaoğlu',
      'Burak',
      'Deniz',
    ];
    final presence = [
      for (var i = 0; i < names.length; i++)
        ChatRoomPresence(id: 'u$i', name: names[i], seatIndex: i + 1),
    ];
    final slots = [
      for (var i = 0; i < names.length; i++)
        VoiceRoomSeatSlot(index: i + 1, userId: 'u$i', name: names[i]),
    ];
    final live = VoiceRoomLiveState(
      loading: false,
      presence: presence,
      seatSlots: slots,
      roomSeatCount: 11,
    );
    // Hediye alan koltuklar: rozet yerleşimi büyütmemeli.
    final gifts = {
      for (var i = 0; i < names.length; i++)
        VoiceSeatGiftTotals.idKey('u$i'): SeatGiftAggregate(
          totalCoins: 125000 * (i + 1),
          contributors: const {},
        ),
    };

    for (final width in [320.0, 360.0, 393.0, 440.0]) {
      testWidgets('${width.toInt()} dp: uzun isim + hediye rozeti taşmaz', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width * 3, 900);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            VoiceWebOwnerStage(
              roomKey: 'r1',
              room: _room,
              seatSlots: slots,
              presence: presence,
              configuredSeatCount: 11,
            ),
            overrides: _overrides(live: live, gifts: gifts),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      });
    }
  });

  group('VoiceMicSeat', () {
    testWidgets('koltuk numarasından sahte "Lv" seviyesi üretmez', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const VoiceMicSeat(
            user: ChatRoomPresence(id: 'u1', name: 'Ece', seatIndex: 3),
            seatIndex: 3,
            size: 50,
          ),
        ),
      );
      expect(find.textContaining('Lv'), findsNothing);
      expect(find.text('3'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('sunucu rol simgesi gösterilir', (tester) async {
      await tester.pumpWidget(
        _host(
          const VoiceMicSeat(
            user: ChatRoomPresence(
              id: 'u1',
              name: 'Ece',
              seatIndex: 3,
              roleSymbol: '★',
            ),
            seatIndex: 3,
            size: 50,
          ),
        ),
      );
      expect(find.text('★'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('kilitli boş koltuk dokunulabilir ve erişilebilir', (
      tester,
    ) async {
      var taps = 0;
      var longs = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          VoiceMicSeat(
            seatIndex: 9,
            size: 50,
            locked: true,
            onTap: () => taps++,
            onLongPress: () => longs++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Koltuk 9, kilitli'), findsOneWidget);
      await tester.tap(find.text('Kilitli'));
      await tester.longPress(find.text('Kilitli'));
      expect(taps, 1);
      expect(longs, 1);
      handle.dispose();
    });

    testWidgets('dolu koltuğun tamamı (isim dahil) dokunulabilir', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          VoiceMicSeat(
            user: const ChatRoomPresence(
              id: 'u1',
              name: 'Ece',
              seatIndex: 2,
              micOn: false,
            ),
            seatIndex: 2,
            size: 50,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Ece'));
      expect(taps, 1);
      expect(
        find.bySemanticsLabel('Koltuk 2, Ece, mikrofon kapalı'),
        findsOneWidget,
      );
      handle.dispose();
      await _dispose(tester);
    });
  });

  group('VoiceSeatAvatarFrame animasyonları', () {
    Future<bool> ticking(
      WidgetTester tester, {
      required SeatAvatarRole role,
      bool speaking = false,
      bool reduce = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Center(
              child: VoiceSeatAvatarFrame(
                size: 50,
                role: role,
                speaking: speaking,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final scheduled = tester.binding.hasScheduledFrame;
      await tester.pumpWidget(const SizedBox());
      return scheduled;
    }

    testWidgets('konuşmayan konuk koltuğu kare çizmez', (tester) async {
      expect(await ticking(tester, role: SeatAvatarRole.guest), isFalse);
    });

    testWidgets('konuşan koltuk nabız animasyonu oynatır', (tester) async {
      expect(
        await ticking(tester, role: SeatAvatarRole.guest, speaking: true),
        isTrue,
      );
    });

    testWidgets('"animasyonları azalt" açıkken hiçbir koltuk dönmez', (
      tester,
    ) async {
      expect(
        await ticking(
          tester,
          role: SeatAvatarRole.admin,
          speaking: true,
          reduce: true,
        ),
        isFalse,
      );
    });
  });

  group('Oda listesi', () {
    test('konum verisi yoksa uydurma mesafe yazılmaz', () {
      final items = VoiceRoomsDiscoverMapper.nearbyFromRooms(
        const [_room],
        tab: VoiceRoomsNearbyTab.nearby,
      );
      expect(items.single.distance, isEmpty);
    });

    test('sunucu mesafesi korunur', () {
      final items = VoiceRoomsDiscoverMapper.nearbyFromRooms(
        const [
          VoiceRoomEntity(
            id: 'r2',
            slug: 'r2',
            nameTr: 'Oda',
            distanceLabel: '1.2 km',
          ),
        ],
        tab: VoiceRoomsNearbyTab.nearby,
      );
      expect(items.single.distance, '1.2 km');
    });

    testWidgets('mesafesiz kartta konum satırı yok', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyRoomTileCard(
              room: VoiceRoomsDiscoverMapper.nearbyFromRooms(
                const [_room],
                tab: VoiceRoomsNearbyTab.nearby,
              ).single,
            ),
          ),
        ),
      );
      expect(find.text('Yakınınızda'), findsNothing);
      expect(find.text('Katıl'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
