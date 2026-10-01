import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/inbox/presentation/providers/inbox_unread_providers.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_providers.dart';
import 'package:canlifal_social/features/voice_hub/data/mappers/voice_rooms_discover_mapper.dart';
import 'package:canlifal_social/features/voice_hub/domain/repositories/voice_rooms_discover_repository.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pages/voice_rooms_list_page.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pages/voice_rooms_mine_page.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pages/voice_rooms_page.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_rooms_discover_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_rooms_ui/voice_rooms_ui.dart';

const _rooms = <VoiceRoomEntity>[
  VoiceRoomEntity(
    id: 'r1',
    slug: 'r1',
    nameTr: 'Gece Sohbeti uzun bir oda adı taşma testi için',
    descTr: 'Güzel sohbet, yeni dostluklar',
    category: 'chat',
    onlineCount: 128,
    userCount: 128,
    ownerName: 'Admin',
    ownerId: 'u1',
  ),
  VoiceRoomEntity(
    id: 'r2',
    slug: 'r2',
    nameTr: 'Müzik Keyfi',
    category: 'music',
    onlineCount: 96,
    userCount: 96,
    ownerName: 'İlham Perisi',
    ownerId: 'u2',
    isLocked: true,
  ),
  VoiceRoomEntity(
    id: 'r3',
    slug: 'r3',
    nameTr: 'Fal & Astroloji',
    descTr: 'Burçlar, tarot',
    onlineCount: 40,
    userCount: 40,
    ownerName: 'Admin',
    ownerId: 'u1',
  ),
];

class _NoRepo implements VoiceRoomsDiscoverRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier extends VoiceRoomsDiscoverNotifier {
  _FakeNotifier(VoiceRoomsDiscoverViewState initial) : super(_NoRepo()) {
    state = initial;
  }

  @override
  Future<void> bootstrap({bool forceRefresh = false}) async {}

  @override
  Future<void> loadMoreNearby() async {}
}

VoiceRoomsDiscoverViewState _state() => VoiceRoomsDiscoverViewState(
      isBootstrapping: false,
      categories: VoiceRoomsMockData.categories,
      featured: VoiceRoomsDiscoverMapper.featuredFromRooms(_rooms),
      popular: VoiceRoomsDiscoverMapper.popularFromRooms(_rooms),
      nearbyRooms: VoiceRoomsDiscoverMapper.nearbyFromRooms(
        _rooms,
        tab: VoiceRoomsNearbyTab.nearby,
      ),
      trends: VoiceRoomsDiscoverMapper.trendsFromApi([
        {'tag': 'CanlıYayın', 'views': 128},
        {'tag': 'Burçlar', 'views': 96},
      ]),
      speakers: VoiceRoomsDiscoverMapper.speakersFromRooms(_rooms),
      allRooms: _rooms,
    );

Widget _app(Widget home, {List<VoiceRoomEntity> owned = const []}) {
  return ProviderScope(
    overrides: [
      voiceRoomsDiscoverProvider.overrideWith((ref) => _FakeNotifier(_state())),
      myOwnedVoiceRoomsProvider.overrideWith((ref) => owned),
      inboxUnreadCountProvider.overrideWith((ref) => 3),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _size(WidgetTester t, double w, double h) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Ağaç kaldırıldıktan sonra bekleyen zamanlayıcıları boşalt.
Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

void main() {
  group('Sesli Odalar ana ekran', () {
    for (final size in const [Size(320, 3200), Size(360, 3200), Size(430, 3200), Size(900, 3200)]) {
      testWidgets('${size.width.toInt()} px: bölümler görünür, taşma yok', (t) async {
        await _size(t, size.width, size.height);
        await t.pumpWidget(_app(const VoiceRoomsPage(), owned: [_rooms[0], _rooms[2]]));
        await t.pump(const Duration(milliseconds: 600));
        expect(t.takeException(), isNull);
        expect(find.text('Sesli Odalar'), findsOneWidget);
        expect(find.text('Sesinle'), findsOneWidget);
        expect(find.text('Daha Yakın Ol'), findsOneWidget);
        expect(find.text('Odalarım'), findsOneWidget);
        expect(find.text('Popüler Sesli Odalar'), findsOneWidget);
        expect(find.text('Trend Konular'), findsOneWidget);
        expect(find.text('En Aktif Konuşmacılar'), findsOneWidget);
        expect(find.text('Öne Çıkan Kategoriler'), findsOneWidget);
        expect(find.text('Kendi Odanı Aç'), findsOneWidget);
        await _done(t);
      });
    }

    testWidgets('sayfa kendi alt navigasyonunu çizmez (tek nav kabuktan gelir)',
        (t) async {
      await _size(t, 360, 3200);
      await t.pumpWidget(_app(const VoiceRoomsPage()));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Ana Sayfa'), findsNothing);
      expect(find.text('Canlı Yayınlar'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      await _done(t);
    });

    testWidgets('yatay (landscape) ekranda taşma yok', (t) async {
      await _size(t, 800, 360);
      await t.pumpWidget(_app(const VoiceRoomsPage(), owned: [_rooms[0]]));
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      await _done(t);
    });

    testWidgets('büyük yazı tipinde (%160) taşma yok', (t) async {
      await _size(t, 360, 3600);
      await t.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const VoiceRoomsPage(),
          ),
          owned: [_rooms[0]],
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      await _done(t);
    });
  });

  group('Oda listesi ve Odalarım', () {
    testWidgets('liste kartları Müsait/Kilitli rozeti ve Katıl gösterir', (t) async {
      await _size(t, 360, 1200);
      await t.pumpWidget(_app(const VoiceRoomsListPage()));
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      expect(find.text('Katıl'), findsWidgets);
      expect(find.text('Müsait'), findsWidgets);
      expect(find.text('Kilitli'), findsOneWidget);
      await _done(t);
    });

    testWidgets('Odalarım: oda satırı ve Yeni Oda Aç', (t) async {
      await _size(t, 360, 900);
      await t.pumpWidget(_app(const VoiceRoomsMinePage(), owned: [_rooms[0], _rooms[1]]));
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      expect(find.text('2 açık oda'), findsOneWidget);
      expect(find.text('Yeni Oda Aç'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsNWidgets(2));
      await _done(t);
    });
  });

  group('Veri kuralları', () {
    test('müsaitlik: kilitli ve dolu odalar Müsait değildir', () {
      expect(voiceRoomAvailability(_rooms[0]).label, 'Müsait');
      expect(voiceRoomAvailability(_rooms[1]).label, 'Kilitli');
      const full = VoiceRoomEntity(
        id: 'f', slug: 'f', nameTr: 'x', userCount: 10, maxUsers: 10,
      );
      expect(voiceRoomAvailability(full).label, 'Dolu');
    });

    test('konuşmacılar sahibe göre birleşir (dinleyici + oda sayısı)', () {
      final s = VoiceRoomsDiscoverMapper.speakersFromRooms(_rooms);
      final admin = s.firstWhere((e) => e.name == 'Admin');
      expect(admin.roomCount, 2);
      expect(admin.listeners, 168);
    });

    test('sayı biçimi', () {
      expect(voiceRoomsCount(950), '950');
      expect(voiceRoomsCount(12800), '13K');
      expect(voiceRoomsCount(1500), '1.5K');
    });

    test('kategori listesi referanstaki 10 kategori', () {
      expect(
        VoiceRoomsMockData.categories.map((c) => c.label),
        ['Tümü', 'Popüler', 'Sohbet', 'Müzik', 'Aşk', 'Fal & Astroloji', 'Oyun', 'Arkadaşlık', 'Yardım', 'Diğer'],
      );
    });
  });
}
