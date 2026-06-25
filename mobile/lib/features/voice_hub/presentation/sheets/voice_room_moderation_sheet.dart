import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';

class VoiceRoomModerationTarget {
  const VoiceRoomModerationTarget({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isModerator = false,
    this.isSpeaker = false,
  });

  factory VoiceRoomModerationTarget.fromPresence(ChatRoomPresence user) {
    final role = (user.chatRole ?? '').toLowerCase();
    final symbol = user.roleSymbol?.trim();
    final isMod = role == 'moderator' ||
        role == 'mod' ||
        role == 'op' ||
        role == 'sop' ||
        symbol == '@' ||
        symbol == '&';
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
    );
  }

  final String id;
  final String username;
  final String? avatarUrl;
  final bool isModerator;
  final bool isSpeaker;
}

final voiceModerationProvider = StateNotifierProvider.family<
    VoiceModerationNotifier, AsyncValue<void>, String>(
  (ref, roomKey) => VoiceModerationNotifier(ref, roomKey),
);

class VoiceModerationNotifier extends StateNotifier<AsyncValue<void>> {
  VoiceModerationNotifier(this._ref, this._roomKey) : super(const AsyncData(null));

  final Ref _ref;
  final String _roomKey;

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
        () => _ref
            .read(voiceRoomLiveProvider(_roomKey).notifier)
            .assignRoleToUser(targetUserId: userId, roleSymbol: '@'),
      );

  Future<bool> removeModerator(String userId) => _run(
        () => _ref
            .read(voiceRoomLiveProvider(_roomKey).notifier)
            .assignRoleToUser(targetUserId: userId, roleSymbol: '+'),
      );

  Future<bool> approveSpeak(String userId) async {
    state = const AsyncLoading();
    try {
      final ctrl = _ref.read(voiceRoomLiveProvider(_roomKey).notifier);
      for (var seat = 0; seat <= 14; seat++) {
        final err = await ctrl.assignSeat(seatIndex: seat, userId: userId);
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

  Future<String?> kickUser(String userId) async {
    state = const AsyncLoading();
    try {
      final result = await _ref
          .read(voiceRoomLiveProvider(_roomKey).notifier)
          .kickUserModeration(userId: userId, reason: 'Oda moderasyonu');
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
}

/// Sesli oda moderasyon paneli.
Future<void> showVoiceRoomModerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required VoiceRoomModerationTarget targetUser,
  required bool isOwnerOrMod,
  bool? canAddModerators,
  VoidCallback? onGift,
}) async {
  if (!isOwnerOrMod) return;

  final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final allowMods = canAddModerators ?? !room.isFreeRoom;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1030),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VoiceRoomModerationSheet(
      roomKey: roomKey,
      targetUser: targetUser,
      canAddModerators: allowMods,
      onGift: onGift,
    ),
  );
}

class _VoiceRoomModerationSheet extends ConsumerWidget {
  const _VoiceRoomModerationSheet({
    required this.roomKey,
    required this.targetUser,
    required this.canAddModerators,
    this.onGift,
  });

  final String roomKey;
  final VoiceRoomModerationTarget targetUser;
  final bool canAddModerators;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(voiceModerationProvider(roomKey).notifier);
    final state = ref.watch(voiceModerationProvider(roomKey));
    final isLoading = state is AsyncLoading;
    final errorMsg =
        state is AsyncError ? ApiException.userMessage(state.error) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: targetUser.avatarUrl != null &&
                        targetUser.avatarUrl!.isNotEmpty
                    ? NetworkImage(targetUser.avatarUrl!)
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetUser.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (targetUser.isModerator)
                    const Text(
                      'Moderatör',
                      style: TextStyle(color: Color(0xFF6C3FC5), fontSize: 12),
                    ),
                  if (targetUser.isSpeaker)
                    const Text(
                      'Konuşmacı',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          if (errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorMsg,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (onGift != null)
            _ActionTile(
              icon: Icons.card_giftcard_rounded,
              label: 'Hediye gönder',
              color: const Color(0xFFFFD54F),
              onTap: () {
                Navigator.pop(context);
                onGift!();
              },
            ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF6C3FC5)),
            )
          else ...[
            if (canAddModerators)
              _ActionTile(
                icon: Icons.shield_rounded,
                label: targetUser.isModerator
                    ? 'Moderatörlüğü Kaldır'
                    : 'Moderatör Yap',
                color: const Color(0xFF6C3FC5),
                onTap: () async {
                  final ok = targetUser.isModerator
                      ? await notifier.removeModerator(targetUser.id)
                      : await notifier.addModerator(targetUser.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showSnack(
                    context,
                    ok
                        ? (targetUser.isModerator
                            ? 'Moderatörlük kaldırıldı'
                            : '${targetUser.username} moderatör yapıldı')
                        : 'İşlem başarısız',
                    ok,
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white38, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ücretsiz odalarda moderatör atanamaz',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (!targetUser.isSpeaker)
              _ActionTile(
                icon: Icons.back_hand_rounded,
                label: 'Konuşmacı Yap (El Onayla)',
                color: Colors.green,
                onTap: () async {
                  final ok = await notifier.approveSpeak(targetUser.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showSnack(
                    context,
                    ok ? '${targetUser.username} konuşmacı yapıldı' : 'Hata',
                    ok,
                  );
                },
              ),
            _ActionTile(
              icon: Icons.mic_off_rounded,
              label: 'Sustur',
              color: Colors.orange,
              onTap: () async {
                final ok = await notifier.muteUser(targetUser.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  ok ? '${targetUser.username} susturuldu' : 'Hata',
                  ok,
                );
              },
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'Odadan At',
              color: Colors.redAccent,
              onTap: () async {
                final msg = await notifier.kickUser(targetUser.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  msg ?? '${targetUser.username} atıldı',
                  msg != null && !msg.toLowerCase().contains('başarısız'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg, bool ok) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF6C3FC5) : Colors.red,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
    );
  }
}
