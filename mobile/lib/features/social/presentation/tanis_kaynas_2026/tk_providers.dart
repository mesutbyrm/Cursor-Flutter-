import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/social_discovery_feed.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../widgets/discovery_filter_sheet.dart';

/// Üst sekmeler.
enum TkCategory { forYou, online, nearby, interests, rooms }

final tkCategoryProvider = StateProvider<TkCategory>((_) => TkCategory.forYou);

/// "Şu an çevrimiçi" şeridi — `GET /api/social/discovery?filter=online`.
/// `total` gerçek çevrimiçi sayısıdır (son 5 dk aktif).
final tkOnlineUsersProvider =
    FutureProvider.autoDispose<SocialDiscoveryFeed>((ref) async {
  return ref
      .read(socialDiscoveryRemoteProvider)
      .fetchDiscovery(filter: 'online', limit: 20);
});

// ─────────────────────────── Tanışma amacı ───────────────────────────

class TkPurpose {
  const TkPurpose(this.id, this.label, this.hobbyKeyword);

  final String id;
  final String label;

  /// Backend'de amaç alanı yok; ilgi alanına karşılık gelen amaçlar keşfi
  /// `hobbies` üzerinden gerçekten süzer, diğerleri yalnızca kaydedilir.
  final String? hobbyKeyword;
}

const tkPurposes = <TkPurpose>[
  TkPurpose('chat', 'Sohbet', null),
  TkPurpose('friendship', 'Arkadaşlık', null),
  TkPurpose('new_people', 'Yeni İnsanlar', null),
  TkPurpose('gaming', 'Oyun Arkadaşı', 'oyun'),
  TkPurpose('music', 'Müzik', 'müzik'),
  TkPurpose('voice', 'Sesli Sohbet', null),
  TkPurpose('travel', 'Gezi', 'gezi'),
  TkPurpose('relationship', 'İlişki', null),
];

/// TODO(backend): kullanıcı profilinde "tanışma amacı" alanı yok
/// (`/api/user/social-settings` yalnızca hobbies/görünürlük alır). Seçim
/// şimdilik cihazda saklanır.
class TkPurposeNotifier extends StateNotifier<Set<String>> {
  TkPurposeNotifier({required String? userId})
      : _storageKey = 'tanis_kaynas_purposes_v1_${userId ?? 'guest'}',
        super(const {}) {
    _ready = _load();
  }

  final String _storageKey;
  late final Future<void> _ready;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      if (saved != null && mounted) state = saved.toSet();
    } catch (_) {}
  }

  Future<void> toggle(String id) async {
    // Do not let the initial async read overwrite a tap made immediately
    // after the discovery screen opens.
    await _ready;
    if (!mounted) return;
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, next.toList());
    } catch (_) {}
  }
}

final tkPurposeProvider =
    StateNotifierProvider<TkPurposeNotifier, Set<String>>(
  (ref) => TkPurposeNotifier(
    userId: ref.watch(authControllerProvider).valueOrNull?.id,
  ),
);

// ─────────────────────────── Keşif destesi ───────────────────────────

class TkDeckState {
  const TkDeckState({
    this.users = const [],
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.hasMore = true,
    this.total = 0,
  });

  /// Sunucudan gelen (sayfa birleşik) ham liste.
  final List<SocialDiscoveryUser> users;
  final bool loading;
  final bool loadingMore;
  final Object? error;
  final bool hasMore;
  final int total;

  TkDeckState copyWith({
    List<SocialDiscoveryUser>? users,
    bool? loading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
    bool? hasMore,
    int? total,
  }) {
    return TkDeckState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

/// Keşif listesi: sayfalı yükleme + daha önce işlem yapılanları düşme.
class TkDeckNotifier extends StateNotifier<TkDeckState> {
  TkDeckNotifier(this._ref) : super(const TkDeckState()) {
    unawaited(reload());
  }

  final Ref _ref;
  var _page = 0;
  String? _serverFilter;

  /// Bu oturumda geçilen / işlem yapılanlar + sunucudaki gönderilmiş işlemler.
  final handledIds = <String>{};

  Future<void> reload({String? serverFilter}) async {
    _serverFilter = serverFilter;
    _page = 0;
    state = const TkDeckState(loading: true);
    try {
      final sent = await _ref
          .read(socialDiscoveryRemoteProvider)
          .fetchSentActionTargetIds();
      handledIds.addAll(sent);
    } catch (_) {
      // Gönderilmiş işlemler alınamazsa keşif yine gösterilir.
    }
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    await _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final feed = await _ref.read(socialDiscoveryRemoteProvider).fetchDiscovery(
            page: _page + 1,
            filter: _serverFilter,
          );
      _page = feed.page;
      final seen = {for (final u in state.users) u.id};
      final merged = [
        ...state.users,
        for (final u in feed.users)
          if (seen.add(u.id)) u,
      ];
      if (!mounted) return;
      state = state.copyWith(
        users: merged,
        loading: false,
        loadingMore: false,
        clearError: true,
        hasMore: feed.hasMore,
        total: feed.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, loadingMore: false, error: e);
    }
  }

  void markHandled(String id) {
    handledIds.add(id);
    // Liste değişmese de görünür desteyi yeniden hesaplatmak için yayınla.
    state = state.copyWith(users: [...state.users]);
  }
}

final tkDeckProvider =
    StateNotifierProvider.autoDispose<TkDeckNotifier, TkDeckState>(
  (ref) => TkDeckNotifier(ref),
);

/// Görünen deste: istemci filtreleri + kategori + amaç uygulanmış.
List<SocialDiscoveryUser> tkVisibleDeck({
  required List<SocialDiscoveryUser> users,
  required Set<String> handled,
  required DiscoveryFilterState filters,
  required TkCategory category,
  required Set<String> purposes,
  String? myId,
}) {
  final purposeKeywords = [
    for (final p in tkPurposes)
      if (purposes.contains(p.id) && p.hobbyKeyword != null) p.hobbyKeyword!,
  ];
  final out = users.where((u) {
    if (u.id.isEmpty || u.id == myId || handled.contains(u.id)) return false;
    if (filters.onlineOnly && !u.isOnline) return false;
    final age = u.age;
    if (age != null && (age < filters.minAge || age > filters.maxAge)) {
      return false;
    }
    if (filters.city.trim().isNotEmpty) {
      final c = u.city?.toLowerCase() ?? '';
      if (!c.contains(filters.city.trim().toLowerCase())) return false;
    }
    if (filters.goldOnly) {
      final m = u.membership?.toLowerCase() ?? '';
      if (!m.contains('gold') && !m.contains('vip')) return false;
    }
    final q = filters.interestQuery.trim().toLowerCase();
    if (q.isNotEmpty && !u.hobbies.join(' ').toLowerCase().contains(q)) {
      return false;
    }
    if (purposeKeywords.isNotEmpty) {
      final hay = u.hobbies.join(' ').toLowerCase();
      if (!purposeKeywords.any(hay.contains)) return false;
    }
    switch (category) {
      case TkCategory.nearby:
        return u.distanceLabel != null && u.distanceLabel!.isNotEmpty;
      case TkCategory.interests:
        return u.commonHobbies.isNotEmpty;
      case TkCategory.online:
        return u.isOnline;
      case TkCategory.forYou:
      case TkCategory.rooms:
        return true;
    }
  }).toList();
  if (category == TkCategory.interests) {
    out.sort((a, b) => (b.matchPercent ?? 0).compareTo(a.matchPercent ?? 0));
  }
  return out;
}

/// Ekran için birleşik görünür deste.
final tkVisibleDeckProvider =
    Provider.autoDispose<List<SocialDiscoveryUser>>((ref) {
  final deck = ref.watch(tkDeckProvider);
  final notifier = ref.read(tkDeckProvider.notifier);
  return tkVisibleDeck(
    users: deck.users,
    handled: notifier.handledIds,
    filters: ref.watch(discoveryFilterProvider),
    category: ref.watch(tkCategoryProvider),
    purposes: ref.watch(tkPurposeProvider),
    myId: ref.watch(authControllerProvider).valueOrNull?.id,
  );
});

/// "Seninle aynı şeyleri sevenler": yüklenen keşif listesindeki gerçek
/// kullanıcılardan ilgi alanı → kişi sayısı (sabit rakam yok).
List<({String hobby, int count})> tkSharedInterestCounts(
  List<SocialDiscoveryUser> users, {
  int max = 6,
}) {
  final counts = <String, int>{};
  final labels = <String, String>{};
  for (final u in users) {
    final source = u.commonHobbies.isNotEmpty ? u.commonHobbies : u.hobbies;
    for (final h in source.toSet()) {
      final key = h.trim().toLowerCase();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      labels.putIfAbsent(key, () => h.trim());
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in sorted.take(max)) (hobby: labels[e.key]!, count: e.value),
  ];
}
