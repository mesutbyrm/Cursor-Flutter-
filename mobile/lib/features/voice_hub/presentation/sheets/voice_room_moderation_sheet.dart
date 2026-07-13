import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../../gifts/presentation/providers/gift_insights_providers.dart';
import '../../../gifts/presentation/widgets/supporter_badge_pill.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_permissions.dart';

class VoiceRoomModerationTarget {
  const VoiceRoomModerationTarget({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isModerator = false,
    this.isSpeaker = false,
    this.isSop = false,
    this.isMuted = false,
  });

  factory VoiceRoomModerationTarget.fromPresence(ChatRoomPresence user) {
    final role = (user.chatRole ?? '').toLowerCase();
    final symbol = user.roleSymbol?.trim();
    final isMod = role == 'moderator' ||
        role == 'mod' ||
        role == 'op' ||
        symbol == '@';
    final isSop = role == 'sop' || symbol == '&';
    final isSpeaker = user.seatIndex != null ||
        role == 'voice' ||
        symbol == '+' ||
        user.isSpeaking;
    return VoiceRoomModerationTarget(
      id: user.id,
      username: user.displayName,
      avatarUrl: user.image,
      isModerator: isMod,
      isSpeaker: isSpeaker,
      isSop: isSop,
      isMuted: user.isMuted,
    );
  }

  final String id;
  final String username;
  final String? avatarUrl;
  final bool isModerator;
  final bool isSpeaker;
  final bool isSop;
  final bool isMuted;
}

final voiceModerationProvider = StateNotifierProvider.family<
    VoiceModerationNotifier, AsyncValue<void>, String>(
  (ref, roomKey) => VoiceModerationNotifier(ref, roomKey),
);

class VoiceModerationNotifier extends StateNotifier<AsyncValue<void>> {
  VoiceModerationNotifier(this._ref, this._roomKey) : super(const AsyncData(null));

  final Ref _ref;
  final String _roomKey;

  VoiceRoomLiveController get _live =>
      _ref.read(voiceRoomLiveProvider(_roomKey).notifier);

  Future<bool> _run(Future<String?> Function() action) async {
    state = const AsyncLoading();
    try {
      final err = await action();
      if (err != null) {
        state = AsyncError(err, StackTrace.current);
        return false;
      }
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> addModerator(String userId) => _run(
        () => _live.assignRoleToUser(targetUserId: userId, roleSymbol: '@'),
      );

  Future<bool> removeModerator(String userId) => _run(
        () => _live.assignRoleToUser(targetUserId: userId, roleSymbol: '+'),
      );

  Future<bool> addSop(String userId) => _run(
        () => _live.assignRoleToUser(targetUserId: userId, roleSymbol: '&'),
      );

  Future<bool> removeSop(String userId) => _run(
        () => _live.assignRoleToUser(targetUserId: userId, roleSymbol: '+'),
      );

  Future<bool> grantVoice(String userId) async {
    state = const AsyncLoading();
    try {
      for (var seat = 0; seat <= 14; seat++) {
        final err = await _live.assignSeat(seatIndex: seat, userId: userId);
        if (err == null) {
          state = const AsyncData(null);
          return true;
        }
      }
      state = AsyncError(StateError('Boş koltuk bulunamadı'), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeFromSeat(String userId) => _run(
        () => _live.clearUserSeat(userId: userId),
      );

  Future<bool> muteUser(String userId) async {
    state = const AsyncLoading();
    try {
      await _ref.read(chatRoomRemoteProvider).muteUser(
            roomKey: _roomKey,
            userId: userId,
            minutes: 30,
            reason: 'Oda moderasyonu',
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> unmuteUser(String userId) => _run(
        () async {
          try {
            await _ref.read(chatRoomRemoteProvider).unmuteUser(
                  roomKey: _roomKey,
                  userId: userId,
                );
            return null;
          } catch (e) {
            return ApiException.userMessage(e);
          }
        },
      );

  Future<String?> kickUser(String userId) async {
    state = const AsyncLoading();
    try {
      final result = await _live.kickUserModeration(
        userId: userId,
        reason: 'Oda moderasyonu',
      );
      if (result == null) {
        state = AsyncError('Atma işlemi başarısız', StackTrace.current);
        return 'Atma işlemi başarısız';
      }
      state = const AsyncData(null);
      return result.feedbackMessage;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ApiException.userMessage(e);
    }
  }

  Future<bool> banUser(String userId) => _run(
        () => _live.banUserModeration(userId: userId),
      );

  Future<bool> unbanUser(String userId) => _run(
        () => _live.unbanUserModeration(userId: userId),
      );

  Future<bool> assignRoleSymbol(String userId, String symbol) => _run(
        () => _live.assignRoleToUser(
              targetUserId: userId,
              roleSymbol: symbol,
            ),
      );

  Future<bool> addDj(String userId) => _run(() => _live.addRoomDj(userId));

  Future<bool> removeDj(String userId) => _run(() => _live.removeRoomDj(userId));

  Future<bool> transferOwnership(String userId) => _run(
        () => _live.assignRoleToUser(targetUserId: userId, roleSymbol: '~'),
      );

  Future<bool> setRoomMuted(bool mute) => _run(
        () => _live.toggleRoomMute(mute: mute),
      );
}

/// Sesli oda moderasyon paneli — web ile aynı kutu ızgarası.
Future<void> showVoiceRoomModerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required VoiceRoomModerationTarget targetUser,
  required bool isOwnerOrMod,
  VoiceRoomPermissions? perms,
  bool? isOwner,
  bool isTargetDj = false,
  bool? canAddModerators,
  VoidCallback? onGift,
}) async {
  if (!isOwnerOrMod) return;

  final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final live = ref.read(voiceRoomLiveProvider(room.liveKey));
  final effectivePerms = perms ??
      VoiceRoomPermissions.forUser(
        user: ref.read(authControllerProvider).valueOrNull,
        room: room,
        server: live.serverPermissions,
      );
  final owner = isOwner ?? effectivePerms.isRoomOwner;
  final allowMods = canAddModerators ?? !room.isFreeRoom;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1030),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _VoiceRoomModerationSheet(
        roomKey: roomKey,
        targetUser: targetUser,
        perms: effectivePerms,
        isOwner: owner,
        isTargetDj: isTargetDj,
        canAddModerators: allowMods,
        onGift: onGift,
      ),
    ),
  );
}

class _VoiceRoomModerationSheet extends ConsumerWidget {
  const _VoiceRoomModerationSheet({
    required this.roomKey,
    required this.targetUser,
    required this.perms,
    required this.isOwner,
    required this.isTargetDj,
    required this.canAddModerators,
    this.onGift,
  });

  final String roomKey;
  final VoiceRoomModerationTarget targetUser;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final bool isTargetDj;
  final bool canAddModerators;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(voiceModerationProvider(roomKey).notifier);
    final state = ref.watch(voiceModerationProvider(roomKey));
    final roomMuted = ref.watch(
      voiceRoomLiveProvider(roomKey).select((s) => s.roomMuted),
    );
    final isLoading = state is AsyncLoading;
    final errorMsg =
        state is AsyncError ? ApiException.userMessage(state.error) : null;

    final actions = <_ModBox>[
      if (onGift != null)
        _ModBox(
          icon: Icons.card_giftcard_rounded,
          label: 'Hediye At',
          color: const Color(0xFFFFD54F),
          onTap: () {
            Navigator.pop(context);
            onGift!();
          },
        ),
      if (perms.canGiveVoice || isOwner)
        _ModBox(
          icon: targetUser.isSpeaker
              ? Icons.mic_off_rounded
              : Icons.record_voice_over_rounded,
          label: targetUser.isSpeaker ? 'Yetki Al' : 'Ses Ver',
          color: targetUser.isSpeaker ? Colors.orange : Colors.green,
          onTap: () {
            if (targetUser.isSpeaker) {
              _run(context, notifier, () async {
                final ok = await notifier.removeFromSeat(targetUser.id);
                return ok ? 'Konuşma yetkisi alındı' : 'Hata';
              });
            } else {
              _run(context, notifier, () async {
                final ok = await notifier.grantVoice(targetUser.id);
                return ok ? '${targetUser.username} koltuğa alındı' : 'Hata';
              });
            }
          },
        ),
      if (canAddModerators && (perms.canModerate || isOwner))
        _ModBox(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Rol / Yetki',
          color: const Color(0xFF8B5CF6),
          onTap: () => _showRolePicker(context, ref, notifier),
        ),
      if (canAddModerators && (perms.canModerate || isOwner))
        _ModBox(
          icon: Icons.shield_rounded,
          label: targetUser.isModerator ? '@ Mod Kaldır' : '@ Moderatör',
          color: const Color(0xFF25F4EE),
          onTap: () => _run(context, notifier, () async {
            final ok = targetUser.isModerator
                ? await notifier.removeModerator(targetUser.id)
                : await notifier.addModerator(targetUser.id);
            return ok
                ? (targetUser.isModerator ? 'Moderatörlük kaldırıldı' : 'Moderatör yapıldı')
                : 'Hata';
          }),
        ),
      if (canAddModerators && (perms.canBanUsers || isOwner))
        _ModBox(
          icon: Icons.verified_user_rounded,
          label: targetUser.isSop ? '& Yetkili Kaldır' : '& Yetkili',
          color: const Color(0xFFFF6B35),
          onTap: () => _run(context, notifier, () async {
            final ok = targetUser.isSop
                ? await notifier.removeSop(targetUser.id)
                : await notifier.addSop(targetUser.id);
            return ok
                ? (targetUser.isSop ? 'Yetkili kaldırıldı' : 'Yetkili yapıldı')
                : 'Hata';
          }),
        ),
      if (perms.canMuteRoom || isOwner)
        _ModBox(
          icon: roomMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: roomMuted ? 'Sesi Aç' : 'Sesi Kapat',
          color: roomMuted ? Colors.teal : Colors.orange,
          onTap: () => _run(context, notifier, () async {
            final ok = await notifier.setRoomMuted(!roomMuted);
            return ok
                ? (roomMuted ? 'Oda sesi açıldı' : 'Oda sesi kapatıldı')
                : 'Hata';
          }),
        ),
      if (perms.canAssignSeats || isOwner)
        _ModBox(
          icon: Icons.event_seat_rounded,
          label: 'Koltuk Ata',
          color: const Color(0xFF3B82F6),
          onTap: () => _pickEmptySeatAndAssign(context, ref, roomKey, targetUser.id),
        ),
      if (perms.canManageDj || isOwner)
        _ModBox(
          icon: isTargetDj ? Icons.headset_off_rounded : Icons.headphones_rounded,
          label: isTargetDj ? 'DJ\'den Çıkar' : 'DJ Yap',
          color: const Color(0xFFE879F9),
          onTap: () => _run(context, notifier, () async {
            final ok = isTargetDj
                ? await notifier.removeDj(targetUser.id)
                : await notifier.addDj(targetUser.id);
            return ok ? 'DJ güncellendi' : 'Hata';
          }),
        ),
      if (isOwner)
        _ModBox(
          icon: Icons.swap_horiz_rounded,
          label: 'Odayı Devret',
          color: const Color(0xFFFFD700),
          onTap: () => _confirm(
            context,
            title: 'Odayı devret',
            body: '${targetUser.username} oda sahibi yapılsın mı?',
            onConfirm: () => _run(context, notifier, () async {
              final ok = await notifier.transferOwnership(targetUser.id);
              return ok ? 'Oda devredildi' : 'Hata';
            }),
          ),
        ),
      if (perms.canMuteUsers || isOwner)
        _ModBox(
          icon: targetUser.isMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: targetUser.isMuted ? 'Susturmayı Kaldır' : 'Sustur',
          color: targetUser.isMuted ? Colors.lightGreen : Colors.redAccent,
          onTap: () => _run(context, notifier, () async {
            final ok = targetUser.isMuted
                ? await notifier.unmuteUser(targetUser.id)
                : await notifier.muteUser(targetUser.id);
            return ok
                ? (targetUser.isMuted
                    ? 'Susturma kaldırıldı'
                    : '${targetUser.username} susturuldu')
                : 'Hata';
          }),
        ),
      if (perms.canBanUsers || isOwner)
        _ModBox(
          icon: Icons.block_rounded,
          label: 'Banla',
          color: Colors.red,
          onTap: () => _confirm(
            context,
            title: 'Banla',
            body: '${targetUser.username} odadan banlansın mı?',
            onConfirm: () => _run(context, notifier, () async {
              final ok = await notifier.banUser(targetUser.id);
              return ok ? 'Kullanıcı banlandı' : 'Hata';
            }),
          ),
        ),
      if (perms.canKickUsers || isOwner)
        _ModBox(
          icon: Icons.logout_rounded,
          label: 'Kick',
          color: const Color(0xFFB8860B),
          onTap: () => _run(context, notifier, () async {
            final msg = await notifier.kickUser(targetUser.id);
            return msg ?? '${targetUser.username} atıldı';
          }),
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: targetUser.avatarUrl != null &&
                        targetUser.avatarUrl!.isNotEmpty
                    ? canlifalImageProvider(targetUser.avatarUrl!)
                    : null,
                backgroundColor: const Color(0xFF6C3FC5),
                child: targetUser.avatarUrl == null || targetUser.avatarUrl!.isEmpty
                    ? Text(
                        targetUser.username.isNotEmpty
                            ? targetUser.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      targetUser.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (targetUser.id.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _TargetSupporterBadge(userId: targetUser.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF6C3FC5)),
            )
          else
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                ),
                itemCount: actions.length,
                itemBuilder: (context, i) => actions[i],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRolePicker(
    BuildContext context,
    WidgetRef ref,
    VoiceModerationNotifier notifier,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in const [
              ('+', 'Voice'),
              ('@', 'Moderatör'),
              ('&', 'Yetkili'),
              ('~', 'Founder'),
            ])
              ListTile(
                title: Text('${e.$1} ${e.$2}'),
                onTap: () => Navigator.pop(ctx, e.$1),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _run(context, notifier, () async {
      final err = await ref.read(voiceRoomLiveProvider(roomKey).notifier).assignRoleToUser(
            targetUserId: targetUser.id,
            roleSymbol: picked,
          );
      return err ?? 'Rol verildi';
    });
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla')),
        ],
      ),
    );
    if (ok == true && context.mounted) await onConfirm();
  }

  Future<void> _run(
    BuildContext context,
    VoiceModerationNotifier notifier,
    Future<String> Function() action,
  ) async {
    final msg = await action();
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.toLowerCase().contains('hata') ||
                msg.toLowerCase().contains('başarısız')
            ? Colors.red
            : const Color(0xFF6C3FC5),
      ),
    );
  }
}

/// Hedef kullanıcının destekçi rozeti (tıklanan kişi başına tek fetch).
class _TargetSupporterBadge extends ConsumerWidget {
  const _TargetSupporterBadge({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(supporterBadgeProvider(userId));
    final tier = async.asData?.value?.current;
    if (tier == null || tier.code.isEmpty) return const SizedBox.shrink();
    return SupporterBadgePill(code: tier.code, label: tier.label, compact: true);
  }
}

class _ModBox extends StatelessWidget {
  const _ModBox({
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
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kullanıcı yönetimi → "Koltuğa Al": boş koltukları gösterir, seçilene oturtur.
Future<void> _pickEmptySeatAndAssign(
  BuildContext context,
  WidgetRef ref,
  String roomKey,
  String userId,
) async {
  final live = ref.read(voiceRoomLiveProvider(roomKey));
  final occupied = <int, ChatRoomPresence>{
    for (final p in live.presence)
      if (p.seatIndex != null) p.seatIndex!: p,
  };
  const seats = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  final picked = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Boş koltuğa al',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                for (final seat in seats)
                  _SeatPickTile(
                    seat: seat,
                    occupantName: occupied[seat]?.displayName,
                    onTap: occupied.containsKey(seat)
                        ? null
                        : () => Navigator.pop(ctx, seat),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (picked == null || !context.mounted) return;
  final err = await ref
      .read(voiceRoomLiveProvider(roomKey).notifier)
      .assignSeat(seatIndex: picked, userId: userId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(err ?? 'Koltuğa alındı')),
  );
}

class _SeatPickTile extends StatelessWidget {
  const _SeatPickTile({
    required this.seat,
    required this.occupantName,
    required this.onTap,
  });

  final int seat;
  final String? occupantName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final busy = onTap == null;
    return Material(
      color: busy ? const Color(0x22FFFFFF) : const Color(0x3322C55E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                busy ? Icons.event_seat : Icons.event_seat_outlined,
                color: busy ? Colors.white38 : const Color(0xFF4ADE80),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                busy ? '$seat • dolu' : '$seat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: busy ? Colors.white38 : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
