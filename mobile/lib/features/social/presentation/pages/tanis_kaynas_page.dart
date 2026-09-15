import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../widgets/discovery_filter_sheet.dart';
import '../widgets/discovery_swipe_deck.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';
import '../providers/social_discovery_providers.dart';

/// BÖLÜM 21/A6 — Tanış & Kaynaş (discovery, actions, konum, hashtag, takımlar).
class TanisKaynasPage extends ConsumerStatefulWidget {
  const TanisKaynasPage({super.key});

  @override
  ConsumerState<TanisKaynasPage> createState() => _TanisKaynasPageState();
}

class _TanisKaynasPageState extends ConsumerState<TanisKaynasPage>
    with SingleTickerProviderStateMixin {
  var _savingLocation = false;
  late final TabController _tabs;
  final _hashtagQuery = TextEditingController();
  final _skippedUserIds = <String>{};
  DiscoveryFilterState _discoveryFilter = const DiscoveryFilterState();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _hashtagQuery.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(socialDiscoveryFeedProvider);
    ref.invalidate(userLocationSettingsProvider);
    ref.invalidate(socialDiscoveryActionsProvider);
    ref.invalidate(socialTrendingHashtagsProvider);
    ref.invalidate(socialTeamsListProvider);
  }

  Future<void> _postAction(String type, String targetId) async {
    try {
      final res = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: type,
            targetId: targetId,
          );
      ref.invalidate(socialDiscoveryActionsProvider);
      if (!mounted) return;
      final matched = pick(res, ['matched', 'isMatch', 'match']) == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matched ? 'Eşleşme! Karşılıklı beğeni 🎉' : _actionSuccessLabel(type),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  List<SocialDiscoveryUser> _filterDiscoveryUsers(List<SocialDiscoveryUser> users) {
    return users.where((u) {
      if (_skippedUserIds.contains(u.id)) return false;
      if (_discoveryFilter.onlineOnly) {
        final raw = u.raw['user'] is Map
            ? asJsonMap(u.raw['user'])
            : asJsonMap(u.raw);
        if (pick(raw, ['isOnline', 'online']) != true) return false;
      }
      final raw = u.raw['user'] is Map
          ? asJsonMap(u.raw['user'])
          : asJsonMap(u.raw);
      final age = pick(raw, ['age', 'userAge']);
      if (age is num) {
        final a = age.round();
        if (a < _discoveryFilter.minAge || a > _discoveryFilter.maxAge) {
          return false;
        }
      }
      final q = _discoveryFilter.interestQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final interests = pick(raw, ['interests', 'tags', 'hobbies']);
        final hay = interests?.toString().toLowerCase() ?? '';
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openDiscoveryFilters() async {
    final next = await showDiscoveryFilterSheet(
      context,
      initial: _discoveryFilter,
    );
    if (next != null) setState(() => _discoveryFilter = next);
  }

  String _actionSuccessLabel(String type) {
    switch (type) {
      case 'like':
        return 'Beğeni gönderildi';
      case 'friend_request':
        return 'Arkadaşlık isteği gönderildi';
      case 'favorite':
        return 'Favorilere eklendi';
      case 'skip':
        return 'Profil geçildi';
      default:
        return 'İşlem kaydedildi';
    }
  }

  Future<void> _updateLocation({
    required UserLocationSettings current,
    bool? locationEnabled,
    bool? showDistance,
  }) async {
    setState(() => _savingLocation = true);
    try {
      final remote = ref.read(socialDiscoveryRemoteProvider);
      var body = current.toPostBody(
        locationEnabled: locationEnabled,
        showDistance: showDistance,
      );
      if (locationEnabled == true) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
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
              showDistance: showDistance ?? current.showDistance,
              latitude: pos.latitude,
              longitude: pos.longitude,
            );
          }
        }
      }
      await remote.updateLocationSettings(body);
      ref.invalidate(userLocationSettingsProvider);
      ref.invalidate(socialDiscoveryFeedProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(socialDiscoveryFeedProvider);
    final location = ref.watch(userLocationSettingsProvider);
    final actions = ref.watch(socialDiscoveryActionsProvider);
    final hashtags = ref.watch(socialTrendingHashtagsProvider);
    final teams = ref.watch(socialTeamsListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Tanış Kaynaş',
          subtitle: 'Keşfet, etkileşim, hashtag ve takımlar',
          actions: [
            DiscoverIconButton(
              icon: Icons.tune_rounded,
              onPressed: _openDiscoveryFilters,
            ),
          ],
          body: Column(
            children: [
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Keşfet'),
                  Tab(text: 'Etkileşimler'),
                  Tab(text: 'Hashtag & Takım'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          location.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (settings) => _LocationCard(
                              settings: settings,
                              busy: _savingLocation,
                              onLocationEnabled: (v) => _updateLocation(
                                current: settings,
                                locationEnabled: v,
                              ),
                              onShowDistance: (v) => _updateLocation(
                                current: settings,
                                showDistance: v,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          discovery.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: DiscoverAccentLoader()),
                            ),
                            error: (e, _) => DiscoverEmptyState(
                              icon: Icons.wifi_off_rounded,
                              message: ApiException.userMessage(e),
                              actionLabel: 'Yenile',
                              action: _refresh,
                            ),
                            data: (users) {
                              final visible = _filterDiscoveryUsers(users);
                              if (visible.isEmpty) {
                                return const DiscoverEmptyState(
                                  icon: Icons.people_outline_rounded,
                                  message:
                                      'Şu an keşfedilecek profil yok. Konum paylaşımını açıp yenileyin.',
                                );
                              }
                              return DiscoverySwipeDeck(
                                users: visible,
                                onOpenProfile: (u) => showSocialDiscoveryProfileSheet(
                                  context,
                                  user: u,
                                  onLike: () => _postAction('like', u.id),
                                  onSkip: () async {
                                    setState(() => _skippedUserIds.add(u.id));
                                    try {
                                      await ref
                                          .read(socialDiscoveryRemoteProvider)
                                          .postAction(
                                            type: 'skip',
                                            targetId: u.id,
                                          );
                                    } catch (_) {}
                                  },
                                ),
                                onLike: (u) => _postAction('like', u.id),
                                onSkip: (u) async {
                                  setState(() => _skippedUserIds.add(u.id));
                                  try {
                                    await ref
                                        .read(socialDiscoveryRemoteProvider)
                                        .postAction(type: 'skip', targetId: u.id);
                                  } catch (_) {}
                                },
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
                    ),
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: actions.when(
                        loading: () => ListView(
                          children: [
                            SizedBox(
                              height: 120,
                              child: const Center(
                                child: DiscoverAccentLoader(),
                              ),
                            ),
                          ],
                        ),
                        error: (e, _) => ListView(
                          children: [
                            DiscoverEmptyState(
                              icon: Icons.history_rounded,
                              message: ApiException.userMessage(e),
                              actionLabel: 'Yenile',
                              action: _refresh,
                            ),
                          ],
                        ),
                        data: (rows) {
                          if (rows.isEmpty) {
                            return ListView(
                              children: [
                                const DiscoverEmptyState(
                                  icon: Icons.inbox_outlined,
                                  message: 'Henüz sosyal etkileşim kaydı yok.',
                                ),
                              ],
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              final type =
                                  (pick(row, ['type', 'action']) ?? '')
                                      .toString();
                              final target =
                                  (pick(row, ['targetId', 'userId']) ?? '')
                                      .toString();
                              return Card(
                                child: ListTile(
                                  title: Text(_actionSuccessLabel(type)),
                                  subtitle: Text(
                                    target.isNotEmpty
                                        ? 'Hedef: $target'
                                        : row.toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          TextField(
                            controller: _hashtagQuery,
                            decoration: InputDecoration(
                              labelText: 'Hashtag ara',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () async {
                                  final q = _hashtagQuery.text.trim();
                                  if (q.isEmpty) return;
                                  try {
                                    final res = await ref
                                        .read(socialDiscoveryRemoteProvider)
                                        .searchHashtags(q: q);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res.isEmpty
                                              ? 'Sonuç yok'
                                              : 'Hashtag verisi alındı',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ApiException.userMessage(e),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Trend hashtag',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          hashtags.when(
                            loading: () => const DiscoverAccentLoader(),
                            error: (e, _) => Text(ApiException.userMessage(e)),
                            data: (map) {
                              final list = pick(map, [
                                'hashtags',
                                'items',
                                'trending',
                              ]);
                              if (list is! List || list.isEmpty) {
                                return const Text('Trend verisi yok');
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final h in list)
                                    if (h is Map)
                                      ActionChip(
                                        label: Text(
                                          '#${pick(Map<String, dynamic>.from(h), ['name', 'tag']) ?? ''}',
                                        ),
                                        onPressed: () async {
                                          final row =
                                              Map<String, dynamic>.from(h);
                                          final name =
                                              pick(row, ['name', 'tag'])
                                                  ?.toString();
                                          if (name == null || name.isEmpty) {
                                            return;
                                          }
                                          try {
                                            await ref
                                                .read(
                                                  socialDiscoveryRemoteProvider,
                                                )
                                                .fetchHashtag(name);
                                          } catch (_) {}
                                        },
                                      ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Takımlar',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          teams.when(
                            loading: () => const DiscoverAccentLoader(),
                            error: (e, _) => Text(ApiException.userMessage(e)),
                            data: (map) {
                              final list = pick(map, ['teams', 'items', 'data']);
                              if (list is! List || list.isEmpty) {
                                return const Text('Takım listesi boş');
                              }
                              return Column(
                                children: [
                                  for (final t in list)
                                    if (t is Map)
                                      Card(
                                        child: ListTile(
                                          title: Text(
                                            (pick(
                                                  Map<String, dynamic>.from(t),
                                                  ['name', 'title'],
                                                ) ??
                                                '')
                                                .toString(),
                                          ),
                                          subtitle: Text(
                                            (pick(
                                                  Map<String, dynamic>.from(t),
                                                  ['id'],
                                                ) ??
                                                '')
                                                .toString(),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () {
                                            final id = pick(
                                              Map<String, dynamic>.from(t),
                                              ['id'],
                                            )?.toString();
                                            if (id != null && id.isNotEmpty) {
                                              context.push('/teams/$id');
                                            }
                                          },
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.settings,
    required this.busy,
    required this.onLocationEnabled,
    required this.onShowDistance,
  });

  final UserLocationSettings settings;
  final bool busy;
  final ValueChanged<bool> onLocationEnabled;
  final ValueChanged<bool> onShowDistance;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surfaceElevated.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Konum ile keşfet'),
              subtitle: const Text('Yakındaki profiller için konum paylaşımı'),
              value: settings.locationEnabled,
              onChanged: busy ? null : onLocationEnabled,
            ),
            SwitchListTile(
              title: const Text('Mesafemi göster'),
              value: settings.showDistance,
              onChanged:
                  busy || !settings.locationEnabled ? null : onShowDistance,
            ),
          ],
        ),
      ),
    );
  }
}
