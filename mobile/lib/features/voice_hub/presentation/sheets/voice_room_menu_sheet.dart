import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import 'voice_room_hub_settings.dart';
import 'voice_room_sheets.dart';
import 'voice_youtube_song_sheet.dart';

/// Faz 3 — 3 nokta menüsü: kullanıcı + yetki + Material 3 büyük kartlar.
Future<void> showVoiceRoomMenuSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
  VoidCallback? onPkInvite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _VoiceRoomMenuSheet(
        room: room,
        live: live,
        perms: perms,
        isOwner: isOwner,
        onUserTap: onUserTap,
        onPkInvite: onPkInvite,
      ),
    ),
  );
}

class _VoiceRoomMenuSheet extends ConsumerWidget {
  const _VoiceRoomMenuSheet({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
    this.onUserTap,
    this.onPkInvite,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onPkInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final dj = live.dj;
    final pk = ref.watch(pkBattleRemoteProvider);
    final pkActive = pk != null && !pk.isEnded;
    final isDj = user != null &&
        (room.djUserIds.contains(user.id) ||
            dj.djUsers.any((u) => u.id == user.id));
    final showDj = VoiceMusicAccess.canShowDjMusicPanel(
      perms: perms,
      isDj: isDj,
    );
    final role = VoiceRoomMenuRole.label(perms, user: user, live: live);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final actions = <_MenuAction>[
      _MenuAction(
        icon: pkActive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
        color: VoiceRoomTokens.neonPink,
        tooltip: pkActive ? 'PK savaşı' : 'PK daveti',
        onTap: () {
          Navigator.pop(context);
          if (pkActive) {
            final key =
                room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
            context.push('/voice-room/$key/pk', extra: room);
          } else if (onPkInvite != null) {
            onPkInvite!();
          } else {
            final key =
                room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
            context.push('/voice-room/$key/pk-invite', extra: room);
          }
        },
      ),
      _MenuAction(
        icon: Icons.tune_rounded,
        color: VoiceRoomTokens.neonBlue,
        tooltip: 'Oda ayarları',
        onTap: () {
          Navigator.pop(context);
          showVoiceRoomSettingsSheet(
            context,
            ref,
            room: room,
            isOwner: isOwner,
            perms: perms,
            presence: live.presence,
            onUserTap: onUserTap,
          );
        },
      ),
      _MenuAction(
        icon: Icons.person_rounded,
        color: VoiceRoomTokens.neonPurple,
        tooltip: 'Kullanıcı ayarları',
        onTap: () {
          Navigator.pop(context);
          showVoiceEffectsSheet(context, ref);
        },
      ),
      _MenuAction(
        icon: Icons.music_note_rounded,
        color: VoiceRoomTokens.gold,
        tooltip: 'Şarkı isteği',
        onTap: () {
          Navigator.pop(context);
          showVoiceYoutubeSongSheet(
            context,
            ref,
            room: room,
            perms: perms,
          );
        },
      ),
      _MenuAction(
        icon: Icons.headphones_rounded,
        color: const Color(0xFF7B2FF7),
        tooltip: 'DJ paneli',
        enabled: showDj,
        onTap: () {
          if (!showDj) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('DJ paneli için yetkiniz yok')),
            );
            return;
          }
          Navigator.pop(context);
          showVoiceMusicControlHub(
            context,
            ref,
            room: room,
            perms: perms,
            isOwner: isOwner,
          );
        },
      ),
      _MenuAction(
        icon: Icons.wallpaper_rounded,
        color: const Color(0xFF22C55E),
        tooltip: 'Arkaplan',
        enabled: perms.canChangeBackground || isOwner,
        onTap: () {
          if (!perms.canChangeBackground && !isOwner) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Arka plan değiştirme yetkiniz yok')),
            );
            return;
          }
          Navigator.pop(context);
          showVoiceRoomBackgroundSheet(
            context,
            ref,
            room: room,
          );
        },
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return VoiceGlass(
          borderRadius: 28,
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _UserHeader(user: user, role: role),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: actions.length,
                itemBuilder: (context, i) => _MenuActionCard(action: actions[i]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user, required this.role});

  final UserEntity? user;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = user?.display.trim().isNotEmpty == true
        ? user!.display.trim()
        : (user?.username.trim().isNotEmpty == true
            ? user!.username.trim()
            : 'Misafir');

    return Row(
      children: [
        VoiceNeonAvatar(
          url: user?.avatarUrl,
          size: 52,
          roleLabel: null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👤 $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Yetkisi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: VoiceRoomTokens.gold.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuAction {
  const _MenuAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;
}

class _MenuActionCard extends StatelessWidget {
  const _MenuActionCard({required this.action});

  final _MenuAction action;

  @override
  Widget build(BuildContext context) {
    final c = action.color;
    final enabled = action.enabled;

    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? action.onTap : action.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.withValues(alpha: enabled ? 0.28 : 0.1),
                  c.withValues(alpha: enabled ? 0.12 : 0.05),
                ],
              ),
              border: Border.all(
                color: c.withValues(alpha: enabled ? 0.45 : 0.2),
                width: 1.2,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                action.icon,
                size: 44,
                color: enabled ? c : c.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Menü üst bilgisi — oda içi yetki etiketi.
abstract final class VoiceRoomMenuRole {
  static String label(
    VoiceRoomPermissions perms, {
    UserEntity? user,
    VoiceRoomLiveState? live,
  }) {
    if (perms.isSiteAdmin) return 'Admin';
    if (perms.isRoomOwner) return 'Kurucu';
    if (perms.canBanUsers) return 'Yetkili (&)';
    if (perms.canModerate) return 'Moderatör (@)';
    if (perms.canGiveVoice || perms.canTakeSeat) return 'Konuşmacı (+)';
    if (user != null && live != null) {
      ChatRoomPresence? self;
      for (final p in live.presence) {
        if (p.id == user.id) {
          self = p;
          break;
        }
      }
      final sym = self?.roleSymbol?.trim();
      if (sym == 'V' || sym == 'v') return 'VIP (V)';
    }
    return 'Normal';
  }
}
