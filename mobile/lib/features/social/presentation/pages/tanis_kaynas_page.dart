import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/discover_voice_rooms.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../tanis_kaynas_2026/tk_common.dart';
import '../tanis_kaynas_2026/tk_discovery_card.dart';
import '../tanis_kaynas_2026/tk_highlights.dart';
import '../tanis_kaynas_2026/tk_palette.dart';
import '../tanis_kaynas_2026/tk_providers.dart';
import '../tanis_kaynas_2026/tk_sections.dart';
import '../utils/discovery_action_feedback.dart';
import '../widgets/discovery_filter_sheet.dart';
import '../widgets/discovery_match_dialog.dart';
import '../widgets/story_create_sheet.dart';

/// Tanış Kaynaş — Premium 2026. Veriler:
/// - Keşif: `GET /api/social/discovery` (`filter=online` çevrimiçi şerit)
/// - Beğen / Tanış: `POST /api/social/actions` (`like` / `friend_request`)
/// - Konum: `GET/POST /api/user/location` (yalnızca mesafe bandı gösterilir)
/// - Odalar: mevcut sesli oda listesi + `navigateToVoiceRoom`
class TanisKaynasPage extends ConsumerStatefulWidget {
  const TanisKaynasPage({super.key, this.initialInterestQuery});

  /// Derin link: `/social/tanis-kaynas?interest=müzik`
  final String? initialInterestQuery;

  @override
  ConsumerState<TanisKaynasPage> createState() => _TanisKaynasPageState();
}

class _TanisKaynasPageState extends ConsumerState<TanisKaynasPage> {
  final _roomsKey = GlobalKey();
  final _deckKey = GlobalKey();
  var _actionBusy = false;
  var _enablingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = widget.initialInterestQuery?.trim();
      if (q == null || q.isEmpty) return;
      ref.read(discoveryFilterProvider.notifier).state =
          ref.read(discoveryFilterProvider).copyWith(interestQuery: q);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(tkOnlineUsersProvider);
    ref.invalidate(socialDiscoveryIncomingLikesProvider);
    ref.invalidate(socialDiscoverySentLikesProvider);
    ref.invalidate(socialDiscoveryMatchesProvider);
    ref.invalidate(userLocationSettingsProvider);
    ref.invalidate(voiceRoomsProvider);
    final online = ref.read(tkCategoryProvider) == TkCategory.online;
    await ref
        .read(tkDeckProvider.notifier)
        .reload(serverFilter: online ? 'online' : null);
  }

  void _selectCategory(TkCategory cat) {
    final prev = ref.read(tkCategoryProvider);
    ref.read(tkCategoryProvider.notifier).state = cat;
    if (cat == TkCategory.rooms) {
      _scrollTo(_roomsKey);
      return;
    }
    // Yalnızca "Çevrimiçi" sunucu süzgeci; diğerleri istemcide.
    final wasOnline = prev == TkCategory.online;
    final isOnline = cat == TkCategory.online;
    if (wasOnline != isOnline) {
      unawaited(
        ref
            .read(tkDeckProvider.notifier)
            .reload(serverFilter: isOnline ? 'online' : null),
      );
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _openFilters() async {
    final next = await showDiscoveryFilterSheet(
      context,
      initial: ref.read(discoveryFilterProvider),
    );
    if (next == null || !mounted) return;
    ref.read(discoveryFilterProvider.notifier).state = next;
  }

  void _openProfile(SocialDiscoveryUser user) {
    showSocialDiscoveryProfileSheet(
      context,
      user: user,
      onLike: () => _act(user, TkSwipeAction.like),
      onSkip: () => _act(user, TkSwipeAction.pass),
      onBlocked: () => ref.read(tkDeckProvider.notifier).markHandled(user.id),
    );
  }

  Future<void> _act(SocialDiscoveryUser user, TkSwipeAction action) async {
    final deck = ref.read(tkDeckProvider.notifier);
    if (action == TkSwipeAction.pass) {
      // Backend'de "geç" işlemi yok; yalnızca bu oturumda desteden düşer.
      deck.markHandled(user.id);
      return;
    }
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final result = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: action == TkSwipeAction.like ? 'like' : 'friend_request',
            targetId: user.id,
          );
      if (!mounted) return;
      final duplicate = result.statusCode == 409;
      if (!result.success && !duplicate) {
        showDiscoveryActionFailure(context, result);
        return;
      }
      deck.markHandled(user.id);
      final message = result.message?.toLowerCase() ?? '';
      // Karşı taraf da istek atmışsa sunucu otomatik kabul eder → eşleşme.
      final matched = result.matched || message.contains('kabul');
      if (action == TkSwipeAction.meet && matched) {
        ref.invalidate(socialDiscoveryMatchesProvider);
        await showDiscoveryMatchDialog(
          context,
          matchedUser: user,
          myAvatarUrl:
              ref.read(authControllerProvider).valueOrNull?.avatarUrl,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              action == TkSwipeAction.meet
                  ? '${user.displayName} için tanışma isteği gönderildi'
                  : '${user.displayName} beğenildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  /// Konum izni + yaklaşık konum gönderimi (`POST /api/user/location`).
  /// Sunucu koordinatı yalnızca mesafe bandı hesaplamak için kullanır.
  Future<void> _enableLocation() async {
    setState(() => _enablingLocation = true);
    try {
      final current = await ref.read(userLocationSettingsProvider.future);
      var body = current.toPostBody(locationEnabled: true);
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 8),
            ),
          );
          body = current.toPostBody(
            locationEnabled: true,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum izni verilmedi'),
              ),
            );
          }
          return;
        }
      }
      await ref.read(socialDiscoveryRemoteProvider).updateLocationSettings(body);
      ref.invalidate(userLocationSettingsProvider);
      await ref.read(tkDeckProvider.notifier).reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _enablingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    final canPop = context.canPop();
    return Scaffold(
      backgroundColor: p.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.backgroundTop, p.background],
            stops: const [0, 0.45],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TkPalette.pink,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: TanisKaynasHeader(
                    onBack: canPop ? () => context.pop() : null,
                    onSearch: () => context.push('/search'),
                    onNotifications: () => context.push('/notifications'),
                    onFilter: _openFilters,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: TanisKaynasCategoryTabs(onSelected: _selectCategory),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                const SliverToBoxAdapter(child: TkActivityStatsStrip()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: OnlineUsersSection(
                    onAddStory: () => showStoryCreateSheet(context, ref),
                    onOpenUser: _openProfile,
                    onSeeAll: () => _selectCategory(TkCategory.online),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  key: _deckKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DiscoveryArea(
                      busy: _actionBusy,
                      onAction: _act,
                      onOpenProfile: _openProfile,
                      onEditFilters: _openFilters,
                      onOpenActivity: () =>
                          context.push('/social/tanis-kaynas/activity'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                const SliverToBoxAdapter(child: TkIcebreakerCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                const SliverToBoxAdapter(child: MeetingPurposeSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: TkQuickActionsGrid(
                    onAddStory: () => showStoryCreateSheet(context, ref),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _NearbyAndInterests(
                      enablingLocation: _enablingLocation,
                      onEnableLocation: _enableLocation,
                      onOpenUser: _openProfile,
                      onSeeNearby: () => _selectCategory(TkCategory.nearby),
                      onTapInterest: (hobby) {
                        ref.read(discoveryFilterProvider.notifier).state = ref
                            .read(discoveryFilterProvider)
                            .copyWith(interestQuery: hobby);
                        _scrollTo(_deckKey);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  key: _roomsKey,
                  child: LiveRoomsSection(
                    onSeeAll: () => context.push('/voice-rooms'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 96,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keşif kartı alanı: yükleniyor / hata / boş / kart.
class _DiscoveryArea extends ConsumerWidget {
  const _DiscoveryArea({
    required this.busy,
    required this.onAction,
    required this.onOpenProfile,
    required this.onEditFilters,
    required this.onOpenActivity,
  });

  final bool busy;
  final void Function(SocialDiscoveryUser, TkSwipeAction) onAction;
  final ValueChanged<SocialDiscoveryUser> onOpenProfile;
  final VoidCallback onEditFilters;
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TkPalette.of(context);
    final deck = ref.watch(tkDeckProvider);
    final visible = ref.watch(tkVisibleDeckProvider);
    final filters = ref.watch(discoveryFilterProvider);
    final matchCount =
        ref.watch(socialDiscoveryMatchesProvider).valueOrNull?.length ?? 0;

    // Görünür deste azalınca sonraki sayfayı arka planda getir.
    if (!deck.loading && deck.hasMore && visible.length < 3) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(tkDeckProvider.notifier).loadMore(),
      );
    }

    final Widget body;
    if (deck.loading && deck.users.isEmpty) {
      body = const TkDiscoveryCardSkeleton(key: ValueKey('skeleton'));
    } else if (deck.error != null && deck.users.isEmpty) {
      body = TkErrorState(
        key: const ValueKey('error'),
        message: ApiException.userMessage(deck.error!),
        onRetry: () => ref.read(tkDeckProvider.notifier).reload(),
      );
    } else if (visible.isEmpty) {
      body = deck.loadingMore
          ? const TkDiscoveryCardSkeleton(key: ValueKey('more'))
          : TkEmptyState(
              key: const ValueKey('empty'),
              title: 'Henüz sana uygun biri bulunamadı.',
              message:
                  'Filtrelerini değiştirerek daha fazla kişi keşfedebilirsin.',
              actionLabel: 'Filtreleri Düzenle',
              onAction: onEditFilters,
            );
    } else {
      final user = visible.first;
      body = TkDiscoveryCard(
        key: ValueKey(user.id),
        user: user,
        busy: busy,
        onAction: (a) => onAction(user, a),
        onOpenProfile: () => onOpenProfile(user),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                visible.isEmpty
                    ? 'Keşfet'
                    : 'Keşfet · ${visible.length}${deck.hasMore ? '+' : ''} profil',
                style: TextStyle(
                  color: p.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TkPressable(
              onTap: onOpenActivity,
              semanticLabel: 'Eşleşmeler ve beğeniler',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: p.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: TkPalette.pink, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      matchCount > 0 ? 'Eşleşmeler · $matchCount' : 'Etkinliğim',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (filters.interestQuery.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('İlgi: ${filters.interestQuery}'),
              onDeleted: () => ref.read(discoveryFilterProvider.notifier).state =
                  filters.copyWith(interestQuery: ''),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
              child: child,
            ),
          ),
          child: body,
        ),
        if (visible.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Sağa kaydır: beğen · sola: geç · yukarı: tanış',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textFaint, fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

/// Yakınımdakiler + ortak ilgi alanları (geniş ekranda yan yana).
class _NearbyAndInterests extends ConsumerWidget {
  const _NearbyAndInterests({
    required this.enablingLocation,
    required this.onEnableLocation,
    required this.onOpenUser,
    required this.onSeeNearby,
    required this.onTapInterest,
  });

  final bool enablingLocation;
  final VoidCallback onEnableLocation;
  final ValueChanged<SocialDiscoveryUser> onOpenUser;
  final VoidCallback onSeeNearby;
  final ValueChanged<String> onTapInterest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(tkDeckProvider.select((s) => s.users));
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;
    final nearby = [
      for (final u in users)
        if (u.id != myId &&
            u.distanceLabel != null &&
            u.distanceLabel!.isNotEmpty &&
            !u.distanceLabel!.toLowerCase().contains('gizli'))
          u,
    ];
    final counts = tkSharedInterestCounts(users);
    final nearbyCard = NearbyUsersSection(
      users: nearby,
      onOpenUser: onOpenUser,
      onEnableLocation: onEnableLocation,
      onSeeAll: onSeeNearby,
      enablingLocation: enablingLocation,
    );
    final interestsCard = SharedInterestsSection(
      counts: counts,
      onTapInterest: onTapInterest,
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nearbyCard),
              const SizedBox(width: 12),
              Expanded(child: interestsCard),
            ],
          );
        }
        return Column(
          children: [nearbyCard, const SizedBox(height: 16), interestsCard],
        );
      },
    );
  }
}
