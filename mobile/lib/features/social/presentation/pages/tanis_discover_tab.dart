import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../domain/entities/social_discovery_feed.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../widgets/discovery_filter_sheet.dart';
import '../utils/discovery_action_feedback.dart';
import '../widgets/discovery_match_dialog.dart';
import '../widgets/discovery_swipe_deck.dart';

class _SwipeHistory {
  _SwipeHistory(this.user, this.action);

  final SocialDiscoveryUser user;
  final String action;
}

/// Keşfet sekmesi — swipe destesi + API aksiyonları.
class TanisDiscoverTab extends ConsumerStatefulWidget {
  const TanisDiscoverTab({
    super.key,
    required this.onRefreshParent,
    this.onMatched,
  });

  final Future<void> Function() onRefreshParent;
  final VoidCallback? onMatched;

  @override
  ConsumerState<TanisDiscoverTab> createState() => _TanisDiscoverTabState();
}

class _TanisDiscoverTabState extends ConsumerState<TanisDiscoverTab> {
  final _passedIds = <String>{};
  final _history = <_SwipeHistory>[];
  var _busy = false;
  var _extraPage = 1;
  final _extraUsers = <SocialDiscoveryUser>[];
  var _loadingMore = false;
  var _autoPageFetches = 0;

  List<SocialDiscoveryUser> _dedupeById(List<SocialDiscoveryUser> users) {
    final seen = <String>{};
    final out = <SocialDiscoveryUser>[];
    for (final u in users) {
      if (seen.add(u.id)) out.add(u);
    }
    return out;
  }

  List<SocialDiscoveryUser> _applyClientFilters(List<SocialDiscoveryUser> users) {
    final filters = ref.read(discoveryFilterProvider);
    final myId = ref.read(authControllerProvider).valueOrNull?.id;
    return users.where((u) {
      if (u.id.isEmpty) return false;
      if (myId != null && u.id == myId) return false;
      if (_passedIds.contains(u.id)) return false;
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
        if (!m.contains('gold') && !m.contains('vip') && !m.contains('svip')) {
          return false;
        }
      }
      if (filters.gender.trim().isNotEmpty) {
        final want = filters.gender.trim().toLowerCase();
        final g = u.gender?.toLowerCase();
        if (g != null && g.isNotEmpty && g != want) {
          return false;
        }
      }
      final km = u.distanceKm;
      if (km != null && km > filters.maxDistanceKm) {
        return false;
      }
      final q = filters.interestQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay = u.hobbies.join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    final next = await showDiscoveryFilterSheet(
      context,
      initial: ref.read(discoveryFilterProvider),
    );
    if (next == null) return;
    ref.read(discoveryFilterProvider.notifier).state = next;
    ref.invalidate(socialDiscoveryFeedProvider);
    setState(() {
      _extraPage = 1;
      _extraUsers.clear();
      _passedIds.clear();
      _history.clear();
      _autoPageFetches = 0;
    });
  }

  Future<bool> _isMatchWith(String targetId) async {
    final matches =
        await ref.read(socialDiscoveryRemoteProvider).fetchMatches();
    return matches.any((m) => m.id == targetId);
  }

  Future<void> _afterAction({
    required SocialDiscoveryUser user,
    required String action,
    required SocialDiscoveryActionResult result,
  }) async {
    if (!result.success) {
      if (!mounted) return;
      showDiscoveryActionFailure(context, result);
      return;
    }
    _history.add(_SwipeHistory(user, action));
    ref.invalidate(socialDiscoveryActionsProvider);
    ref.invalidate(socialDiscoveryMatchesProvider);

    var matched = result.matched;
    if (!matched && (action == 'like' || action == 'favorite')) {
      matched = await _isMatchWith(user.id);
    }
    if (matched && mounted) {
      final me = ref.read(authControllerProvider).valueOrNull;
      await showDiscoveryMatchDialog(
        context,
        matchedUser: user,
        myAvatarUrl: me?.avatarUrl,
      );
      widget.onMatched?.call();
    }
  }

  Future<void> _like(SocialDiscoveryUser user) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: 'like',
            targetId: user.id,
          );
      await _afterAction(user: user, action: 'like', result: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _superLike(SocialDiscoveryUser user) async {
    final tier = ref.read(vipTierProvider);
    if (!tier.isAtLeast(VipTier.gold)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Süper beğeni Gold üyelik ile kullanılabilir (sunucu: favorite).',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: 'favorite',
            targetId: user.id,
          );
      await _afterAction(user: user, action: 'favorite', result: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip(SocialDiscoveryUser user) async {
    setState(() {
      _passedIds.add(user.id);
      _history.add(_SwipeHistory(user, 'pass'));
    });
  }

  Future<void> _rewind() async {
    if (_history.isEmpty) return;
    final tier = ref.read(vipTierProvider);
    if (!tier.isAtLeast(VipTier.gold)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri alma Gold üyeler için.')),
      );
      return;
    }
    final last = _history.removeLast();
    _passedIds.remove(last.user.id);
    if (last.action == 'like' || last.action == 'favorite') {
      setState(() => _busy = true);
      try {
        await ref.read(socialDiscoveryRemoteProvider).postAction(
              type: last.action == 'favorite' ? 'favorite' : 'like',
              targetId: last.user.id,
            );
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
    setState(() {});
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    _loadingMore = true;
    try {
      final filters = ref.read(discoveryFilterProvider);
      _extraPage++;
      final feed = await ref.read(socialDiscoveryRemoteProvider).fetchDiscovery(
            page: _extraPage,
            minAge: filters.minAge,
            maxAge: filters.maxAge,
            city: filters.city,
            onlineOnly: filters.onlineOnly,
            gender: filters.gender,
            membership: filters.goldOnly ? 'gold' : null,
            interest: filters.interestQuery,
          );
      if (feed.users.isNotEmpty) {
        setState(() => _extraUsers.addAll(feed.users));
      }
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(socialDiscoveryFeedProvider);
    final filters = ref.watch(discoveryFilterProvider);
    final location = ref.watch(userLocationSettingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _extraPage = 1;
          _extraUsers.clear();
          _passedIds.clear();
          _history.clear();
          _autoPageFetches = 0;
        });
        ref.invalidate(socialDiscoveryFeedProvider);
        await widget.onRefreshParent();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Yakınındaki profiller',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _openFilters,
                tooltip: 'Filtreler',
              ),
            ],
          ),
          if (filters.onlineOnly ||
              filters.goldOnly ||
              filters.city.isNotEmpty ||
              filters.interestQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                children: [
                  if (filters.onlineOnly)
                    const Chip(label: Text('Çevrimiçi')),
                  if (filters.goldOnly) const Chip(label: Text('Gold')),
                  if (filters.city.isNotEmpty)
                    Chip(label: Text(filters.city)),
                  if (filters.interestQuery.isNotEmpty)
                    Chip(label: Text('#${filters.interestQuery}')),
                  if (filters.maxDistanceKm < 200)
                    Chip(label: Text('≤${filters.maxDistanceKm} km')),
                ],
              ),
            ),
          location.when(
            data: (settings) {
              if (settings.locationEnabled) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.location_off_outlined),
                  title: const Text('Konum kapalı'),
                  subtitle: const Text(
                    'Yakındaki profiller için üstteki “Konum ile keşfet” bölümünü açın.',
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          discovery.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => DiscoverEmptyInline(
              icon: Icons.wifi_off_rounded,
              title: 'Profiller yüklenemedi',
              subtitle: ApiException.userMessage(e),
            ),
            data: (feed) {
              final merged = _dedupeById([...feed.users, ..._extraUsers]);
              final visible = _applyClientFilters(merged);
              if (visible.isEmpty) {
                if (feed.hasMore && _autoPageFetches < 4 && !_loadingMore) {
                  _autoPageFetches++;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadMore();
                  });
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const DiscoverEmptyInline(
                  icon: Icons.people_outline_rounded,
                  title: 'Şimdilik yeni profil yok',
                  subtitle:
                      'Filtreleri gevşetin veya konum paylaşımını açıp yenileyin.',
                );
              }
              _autoPageFetches = 0;
              final tier = ref.watch(vipTierProvider);
              return DiscoverySwipeDeck(
                users: visible,
                busy: _busy,
                canRewind:
                    _history.isNotEmpty && tier.isAtLeast(VipTier.gold),
                canSuperLike: tier.isAtLeast(VipTier.gold),
                onNeedMore: feed.hasMore || _extraUsers.isNotEmpty
                    ? _loadMore
                    : null,
                onOpenProfile: (u) => showSocialDiscoveryProfileSheet(
                  context,
                  user: u,
                  onLike: () => _like(u),
                  onSkip: () => _skip(u),
                  onBlocked: () {
                    setState(() => _passedIds.add(u.id));
                  },
                ),
                onLike: _like,
                onSkip: _skip,
                onSuperLike: _superLike,
                onRewind: _rewind,
                onReport: (u) => openReportFlow(
                  context,
                  ReportTarget(
                    type: ReportTargetType.user,
                    targetId: u.id,
                    displayTitle: u.displayName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
