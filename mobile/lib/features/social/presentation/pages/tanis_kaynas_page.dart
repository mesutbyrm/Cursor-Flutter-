import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';
import '../providers/social_discovery_providers.dart';

/// BÖLÜM 21/A6 — Tanış & Kaynaş (`/api/social/discovery`, actions, konum).
class TanisKaynasPage extends ConsumerStatefulWidget {
  const TanisKaynasPage({super.key});

  @override
  ConsumerState<TanisKaynasPage> createState() => _TanisKaynasPageState();
}

class _TanisKaynasPageState extends ConsumerState<TanisKaynasPage> {
  var _savingLocation = false;

  Future<void> _refresh() async {
    ref.invalidate(socialDiscoveryFeedProvider);
    ref.invalidate(userLocationSettingsProvider);
  }

  Future<void> _postAction(String type, String targetId) async {
    try {
      await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: type,
            targetId: targetId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_actionSuccessLabel(type))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  String _actionSuccessLabel(String type) {
    switch (type) {
      case 'like':
        return 'Beğeni gönderildi';
      case 'friend_request':
        return 'Arkadaşlık isteği gönderildi';
      case 'favorite':
        return 'Favorilere eklendi';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Tanış Kaynaş',
          subtitle: 'Yakınındaki kişileri keşfet',
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                    if (users.isEmpty) {
                      return const DiscoverEmptyState(
                        icon: Icons.people_outline_rounded,
                        message:
                            'Şu an keşfedilecek profil yok. Konum paylaşımını açıp yenileyin.',
                      );
                    }
                    return Column(
                      children: [
                        for (final u in users) ...[
                          _DiscoveryUserCard(
                            user: u,
                            onOpenProfile: () =>
                                context.push('/user/${Uri.encodeComponent(u.id)}'),
                            onLike: () => _postAction('like', u.id),
                            onFriendRequest: () =>
                                _postAction('friend_request', u.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
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
              onChanged: busy || !settings.locationEnabled ? null : onShowDistance,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryUserCard extends StatelessWidget {
  const _DiscoveryUserCard({
    required this.user,
    required this.onOpenProfile,
    required this.onLike,
    required this.onFriendRequest,
  });

  final SocialDiscoveryUser user;
  final VoidCallback onOpenProfile;
  final VoidCallback onLike;
  final VoidCallback onFriendRequest;

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Card(
      color: context.colors.surfaceElevated.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(url: u.avatarUrl, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (u.username != null && u.username!.isNotEmpty)
                      Text(
                        '@${u.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                    if (u.distanceLabel != null)
                      Text(
                        u.distanceLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Beğen',
                onPressed: onLike,
                icon: const Icon(Icons.favorite_border_rounded),
              ),
              IconButton(
                tooltip: 'Arkadaşlık isteği',
                onPressed: onFriendRequest,
                icon: const Icon(Icons.person_add_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
