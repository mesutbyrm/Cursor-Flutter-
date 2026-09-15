import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';
import '../providers/social_discovery_providers.dart';
import 'tanis_discover_tab.dart';
import 'tanis_matches_tab.dart';

/// Tanış & Kaynaş — swipe keşif, eşleşmeler, etkileşimler.
class TanisKaynasPage extends ConsumerStatefulWidget {
  const TanisKaynasPage({super.key});

  @override
  ConsumerState<TanisKaynasPage> createState() => _TanisKaynasPageState();
}

class _TanisKaynasPageState extends ConsumerState<TanisKaynasPage>
    with SingleTickerProviderStateMixin {
  var _savingLocation = false;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(socialDiscoveryFeedProvider);
    ref.invalidate(socialDiscoveryMatchesProvider);
    ref.invalidate(userLocationSettingsProvider);
    ref.invalidate(socialDiscoveryActionsProvider);
    ref.invalidate(socialTrendingHashtagsProvider);
    ref.invalidate(socialTeamsListProvider);
  }

  SocialDiscoveryUser? _interactionTargetUser(Map<String, dynamic> row) {
    return SocialDiscoveryUser.fromActionRow(row);
  }

  String _actionSuccessLabel(String type) {
    switch (type) {
      case 'like':
        return 'Beğeni';
      case 'favorite':
        return 'Süper beğeni (favori)';
      case 'friend_request':
        return 'Arkadaşlık isteği';
      case 'skip':
        return 'Geçildi';
      default:
        return type;
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

  void _openHashtagTeams(BuildContext context) {
    context.push('/social/tanis-kaynas/extras');
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(userLocationSettingsProvider);
    final actions = ref.watch(socialDiscoveryActionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Tanış Kaynaş',
          subtitle: 'Swipe ile keşfet · gerçek eşleşmeler',
          actions: [
            DiscoverIconButton(
              icon: Icons.tag_rounded,
              onPressed: () => _openHashtagTeams(context),
            ),
          ],
          body: Column(
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
              Consumer(
                builder: (context, ref, _) {
                  final matchCount =
                      ref.watch(socialDiscoveryMatchesProvider).valueOrNull
                              ?.length ??
                          0;
                  return TabBar(
                    controller: _tabs,
                    tabs: [
                      const Tab(text: 'Keşfet'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Eşleşmeler'),
                            if (matchCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: PlatformSocialPalette.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$matchCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Etkileşimler'),
                    ],
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    TanisDiscoverTab(
                      onRefreshParent: _refresh,
                      onMatched: () {
                        if (_tabs.index != 1) {
                          _tabs.animateTo(1);
                        }
                      },
                    ),
                    TanisMatchesTab(onRefresh: _refresh),
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: actions.when(
                        loading: () => ListView(
                          children: const [
                            SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
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
                              children: const [
                                DiscoverEmptyState(
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
                              final targetUser = _interactionTargetUser(row);
                              final targetId = targetUser?.id ?? '';
                              final title = targetUser?.displayName ??
                                  (targetId.isNotEmpty ? targetId : null) ??
                                  _actionSuccessLabel(type);
                              final tile = PlatformSocialInteractionTile(
                                actionLabel: _actionSuccessLabel(type),
                                targetLabel: title,
                                icon: platformSocialActionIcon(type),
                                onTap: targetUser == null
                                    ? null
                                    : () => showSocialDiscoveryProfileSheet(
                                          context,
                                          user: targetUser,
                                        ),
                              );
                              if (targetId.isEmpty) return tile;
                              return AdminUserHubLauncher.wrap(
                                context: context,
                                ref: ref,
                                userId: targetId,
                                onTap: targetUser == null
                                    ? null
                                    : () => showSocialDiscoveryProfileSheet(
                                          context,
                                          user: targetUser,
                                        ),
                                child: tile,
                              );
                            },
                          );
                        },
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: context.colors.surfaceElevated.withValues(alpha: 0.35),
      child: ExpansionTile(
        title: const Text('Konum ile keşfet', style: TextStyle(fontSize: 14)),
        children: [
          SwitchListTile(
            title: const Text('Konum paylaşımı'),
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
    );
  }
}
