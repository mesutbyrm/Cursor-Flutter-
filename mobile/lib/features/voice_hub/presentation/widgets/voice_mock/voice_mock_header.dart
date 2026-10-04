import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gift_box/presentation/widgets/gift_box_chest_button.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../providers/voice_room_ranking_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// 1 234 → 1.2K · 1 600 000 → 1.6M
String voiceMockCompactCount(int v) {
  if (v >= 1000000) {
    final m = v / 1000000;
    return '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (v >= 1000) {
    final k = v / 1000;
    return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}K';
  }
  return '$v';
}

int? _hourlyRank(VoiceRoomRankingState state, String roomKey) {
  final id = roomKey.trim();
  if (id.isEmpty) return null;
  for (final e in state.hourly) {
    if (e.room.apiRoomKey == id || e.room.id == id) return e.rank;
  }
  return null;
}

/// Sesli oda üst bar — mockup: sahip avatarı + oda adı + #sıra + ID, sağda jeton /
/// çevrimiçi / çıkış; ikinci satırda «Popüler Oda» ve Sıralama · Davet Et · Ayarlar.
class VoiceMockHeader extends ConsumerWidget {
  const VoiceMockHeader({
    super.key,
    required this.roomLookupKey,
    required this.liveRoomKey,
    required this.fallbackRoom,
    required this.onBack,
    required this.onExit,
    required this.onAudience,
    required this.onCoinsTap,
    required this.onRanking,
    required this.onInvite,
    required this.onSettings,
    required this.onPopular,
  });

  final String roomLookupKey;
  final String liveRoomKey;
  final VoiceRoomEntity fallbackRoom;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback onAudience;
  final VoidCallback onCoinsTap;
  final VoidCallback onRanking;
  final VoidCallback onInvite;
  final VoidCallback? onSettings;
  final VoidCallback onPopular;

  VoiceRoomEntity _displayRoom(VoiceRoomEntity? synced) {
    if (synced != null && synced.apiRoomKey.isNotEmpty) return synced;
    if (fallbackRoom.apiRoomKey.isNotEmpty) return fallbackRoom;
    return synced ?? fallbackRoom;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = _displayRoom(
      ref.watch(voiceRoomByIdProvider(roomLookupKey)).valueOrNull,
    );
    final online = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.onlineCountFor(room)),
    );
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    final rank = ref.watch(
      voiceRoomRankingProvider.select((s) => _hourlyRank(s, roomLookupKey)),
    );
    final ownerId = room.ownerId;
    final avatar = ownerId == null
        ? null
        : ref.watch(
            voiceRoomSeatSliceProvider(liveRoomKey).select((slice) {
              for (final p in List.of(slice.presence)) {
                if (p.id == ownerId) return p.image;
              }
              return null;
            }),
          );
    return VoiceMockHeaderView(
      title: room.displayTitle,
      roomKey: room.apiRoomKey,
      icon: room.icon ?? '🎤',
      avatarUrl: avatar,
      rank: rank,
      jeton: jeton,
      online: online,
      onBack: onBack,
      onExit: onExit,
      onAudience: onAudience,
      onCoinsTap: onCoinsTap,
      onRanking: onRanking,
      onInvite: onInvite,
      onSettings: onSettings,
      onPopular: onPopular,
      chest: GiftBoxChestButton(
        scope: (
          roomId: room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id,
          streamId: null,
        ),
      ),
    );
  }
}

/// Saf görünüm — sağlayıcı bağımsız (test/render için).
class VoiceMockHeaderView extends StatelessWidget {
  const VoiceMockHeaderView({
    super.key,
    required this.title,
    required this.roomKey,
    required this.icon,
    required this.avatarUrl,
    required this.rank,
    required this.jeton,
    required this.online,
    required this.onBack,
    required this.onExit,
    required this.onAudience,
    required this.onCoinsTap,
    required this.onRanking,
    required this.onInvite,
    required this.onSettings,
    required this.onPopular,
    this.chest,
  });

  /// «Popüler Oda» yanında hoplayan hediye sandığı (aktif kutu varsa).
  final Widget? chest;
  final String title;
  final String roomKey;
  final String icon;
  final String? avatarUrl;
  final int? rank;
  final int jeton;
  final int online;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback onAudience;
  final VoidCallback onCoinsTap;
  final VoidCallback onRanking;
  final VoidCallback onInvite;
  final VoidCallback? onSettings;
  final VoidCallback onPopular;

  @override
  Widget build(BuildContext context) {
    final shortId = roomKey.length > 8 ? roomKey.substring(0, 8) : roomKey;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              _CrownedAvatar(url: avatarUrl, fallback: icon),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => Clipboard.setData(
                    ClipboardData(text: roomKey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (rank != null) ...[
                            const SizedBox(width: 6),
                            _RankPill(rank: rank!),
                          ],
                        ],
                      ),
                      Text(
                        'ID $shortId',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _StatPill(
                onTap: onCoinsTap,
                color: VoiceRoomTokens.neonBlue,
                icon: Icons.diamond_rounded,
                text: voiceMockCompactCount(jeton),
              ),
              const SizedBox(width: 4),
              _StatPill(
                onTap: onAudience,
                color: const Color(0xFF22C55E),
                icon: Icons.people_alt_rounded,
                text: '·${voiceMockCompactCount(online)}',
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onExit,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.4),
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onPopular,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text(
                        'Popüler Oda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              if (chest != null) ...[
                const SizedBox(width: 8),
                chest!,
              ],
              const Spacer(),
              _TopAction(
                icon: Icons.emoji_events_rounded,
                label: 'Sıralama',
                color: VoiceRoomTokens.gold,
                onTap: onRanking,
              ),
              const SizedBox(width: 8),
              _TopAction(
                icon: Icons.groups_2_rounded,
                label: 'Davet Et',
                color: Colors.white,
                onTap: onInvite,
              ),
              if (onSettings != null) ...[
                const SizedBox(width: 8),
                _TopAction(
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  color: Colors.white,
                  onTap: onSettings!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CrownedAvatar extends StatelessWidget {
  const _CrownedAvatar({required this.url, required this.fallback});

  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return SizedBox(
      width: size,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 8,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: VoiceRoomTokens.goldRing,
              ),
              child: ClipOval(
                child: hasUrl
                    ? Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
          const Positioned(
            top: -2,
            left: 0,
            right: 0,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 22,
              color: VoiceRoomTokens.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => ColoredBox(
        color: const Color(0xFF2A1458),
        child: Center(
          child: Text(fallback, style: const TextStyle(fontSize: 22)),
        ),
      );
}

class _RankPill extends StatelessWidget {
  const _RankPill({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A12).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoiceRoomTokens.gold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 13,
            color: VoiceRoomTokens.gold,
          ),
          const SizedBox(width: 2),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: VoiceRoomTokens.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.text,
  });

  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.85), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
