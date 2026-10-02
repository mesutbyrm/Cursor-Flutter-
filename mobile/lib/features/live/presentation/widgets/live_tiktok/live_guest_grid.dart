import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/live_guest_layout.dart';
import '../../../domain/entities/live_guest_slot.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../providers/live_guest_grid_provider.dart';
import '../../gifts/providers/live_seat_gift_totals_provider.dart';
import '../../gifts/widgets/live_seat_gift_flash_stack.dart';
import 'package:canlifal_social/features/gifts/presentation/widgets/seat_gift_badge.dart';

/// TikTok Party tarzı çoklu yayın grid — 2/4/6/9 koltuk (TRTC).
class LiveGuestGrid extends ConsumerWidget {
  const LiveGuestGrid({
    super.key,
    required this.layout,
    required this.isHost,
    this.trtc,
    this.localPreviewKey,
    this.hostAvatarUrl,
    this.hostName,
    this.remoteUserId,
    this.onInviteSlot,
    this.onGuestAction,
    this.hostJetonEarned = 0,
  });

  final LiveGuestLayout layout;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final Key? localPreviewKey;
  final String? hostAvatarUrl;
  final String? hostName;
  final String? remoteUserId;
  final void Function(int slotIndex)? onInviteSlot;
  final void Function(int slotIndex, String action)? onGuestAction;
  final int hostJetonEarned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(liveGuestGridProvider);
    if (layout == LiveGuestLayout.solo) {
      return _soloView();
    }

    final slots = grid.slots.length >= layout.seats
        ? grid.slots.take(layout.seats).toList()
        : _buildSlots(layout.seats);

    Widget cell(int i) {
      final slot = i < slots.length ? slots[i] : LiveGuestSlot(index: i);
      final remoteId = slot.rtcUserId ?? slot.userId ?? (i == 1 ? remoteUserId : null);
      return _SlotCell(
        slot: slot,
        isHost: isHost,
        trtc: trtc,
        localPreviewKey: i == 0 ? localPreviewKey : null,
        hostAvatarUrl: hostAvatarUrl,
        hostName: hostName,
        remoteUserId: remoteId,
        hostJetonEarned: hostJetonEarned,
        pinned: grid.pinnedIndex == i,
        onInvite: onInviteSlot == null ? null : () => onInviteSlot!(i),
        onAction: onGuestAction == null
            ? null
            : (action) => onGuestAction!(i, action),
      );
    }

    const gap = SizedBox(width: 3, height: 3);

    // 2 kişi: üst/alt (boş alan gösterilmez).
    if (layout == LiveGuestLayout.duo) {
      return Column(
        children: [
          Expanded(child: cell(0)),
          gap,
          Expanded(child: cell(1)),
        ],
      );
    }

    if (layout == LiveGuestLayout.trio) {
      return Row(
        children: [
          Expanded(child: cell(0)),
          gap,
          Expanded(
            child: Column(
              children: [
                Expanded(child: cell(1)),
                gap,
                Expanded(child: cell(2)),
              ],
            ),
          ),
        ],
      );
    }

    if (layout == LiveGuestLayout.quad) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(0)),
                gap,
                Expanded(child: cell(1)),
              ],
            ),
          ),
          gap,
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(2)),
                gap,
                Expanded(child: cell(3)),
              ],
            ),
          ),
        ],
      );
    }

    final cross = layout.crossAxisCount;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: cross == 3 ? 0.62 : 0.55,
      ),
      itemCount: layout.seats,
      itemBuilder: (context, i) => cell(i),
    );
  }

  List<LiveGuestSlot> _buildSlots(int count) {
    return [for (var i = 0; i < count; i++) LiveGuestSlot(index: i, isHost: i == 0)];
  }

  Widget _soloView() {
    if (isHost && trtc != null) {
      return TrtcLocalVideoView(key: localPreviewKey, manager: trtc!);
    }
    if (remoteUserId != null && trtc != null) {
      return TrtcRemoteVideoView(
        key: ValueKey(remoteUserId),
        manager: trtc!,
        userId: remoteUserId!,
      );
    }
    return const ColoredBox(color: Colors.black);
  }
}

class _SlotCell extends ConsumerWidget {
  const _SlotCell({
    required this.slot,
    required this.isHost,
    this.trtc,
    this.localPreviewKey,
    this.hostAvatarUrl,
    this.hostName,
    this.remoteUserId,
    this.pinned = false,
    this.onInvite,
    this.onAction,
    this.hostJetonEarned = 0,
  });

  final LiveGuestSlot slot;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final Key? localPreviewKey;
  final String? hostAvatarUrl;
  final String? hostName;
  final String? remoteUserId;
  final bool pinned;
  final VoidCallback? onInvite;
  final void Function(String action)? onAction;
  final int hostJetonEarned;

  static const _neon = Color(0xFF22D3EE);

  int get _displayJeton =>
      slot.isHost || slot.index == 0 ? hostJetonEarned : slot.jetonEarned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;
    final slotUserId = slot.rtcUserId ?? slot.userId;
    final isSelf = currentUserId != null &&
        ((slotUserId != null && slotUserId == currentUserId) ||
            (isHost && slot.isHost && slotUserId == null));
    final remoteId = isSelf
        ? null
        : (slotUserId ?? (slot.isHost || slot.index == 0 ? remoteUserId : null));

    if (!isSelf && remoteId == null && slot.isEmpty) return _emptySlot();

    final name = slot.displayName ??
        (slot.index == 0 || isSelf ? hostName : null) ??
        (slot.index == 0 ? 'Yayıncı' : 'Konuk');
    final avatar = slot.avatarUrl ?? (slot.index == 0 || isSelf ? hostAvatarUrl : null);

    final videoMap = trtc?.remoteVideoByUser;
    final audioMap = trtc?.remoteAudioByUser;
    final speakingN = trtc?.speakingUsersNotifier;

    Widget body(bool cameraOn, bool micOn, bool speaking) {
      Widget video;
      if (!cameraOn) {
        video = _cameraOffPlaceholder(name, avatar);
      } else if (isSelf) {
        video = trtc != null
            ? TrtcLocalVideoView(key: localPreviewKey, manager: trtc!)
            : _cameraOffPlaceholder(name, avatar);
      } else if (remoteId != null && trtc != null) {
        video = TrtcRemoteVideoView(
          key: ValueKey(remoteId),
          manager: trtc!,
          userId: remoteId,
        );
      } else {
        video = _cameraOffPlaceholder(name, avatar);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: speaking ? _neon : Colors.white.withValues(alpha: 0.08),
            width: speaking ? 2 : 1,
          ),
          boxShadow: speaking
              ? [BoxShadow(color: _neon.withValues(alpha: 0.45), blurRadius: 10)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              video,
              // Alt gradyan — isim/ikon okunaklı kalsın.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 56,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xAA000000)],
                      ),
                    ),
                  ),
                ),
              ),
              if (_displayJeton > 0)
                Positioned(
                  left: 6,
                  top: 6,
                  child: _pill(
                    Icons.favorite_rounded,
                    _fmt(_displayJeton),
                    const Color(0xFFFF2D7A),
                  ),
                ),
              if (pinned)
                Positioned(
                  left: 6,
                  top: _displayJeton > 0 ? 30 : 6,
                  child: _pill(Icons.push_pin_rounded, 'Sabit', Colors.white),
                ),
              if (isHost && slot.index > 0 && onAction != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _miniBtn(Icons.push_pin_outlined, () => onAction!('pin')),
                      _miniBtn(Icons.mic_off_outlined, () => onAction!('mute')),
                      _miniBtn(
                        cameraOn
                            ? Icons.videocam_off_outlined
                            : Icons.videocam_rounded,
                        () => onAction!('cam'),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 6,
                bottom: 6,
                right: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _namePill(name, avatar),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: _micDot(micOn),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: LiveSeatGiftFlashStack(
                  userId: slot.userId ?? (slot.index == 0 ? null : remoteUserId),
                  displayName:
                      slot.displayName ?? (slot.index == 0 ? hostName : null),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 30,
                child: Center(
                  child: SeatGiftBadge(
                    compact: true,
                    receiverName: name,
                    aggregate: ref.watch(
                      liveSeatGiftTotalsProvider.select(
                        (m) => selectSeatGiftAggregate(
                          m,
                          userId: slot.userId ??
                              (slot.index == 0 ? null : remoteUserId),
                          displayName: slot.displayName ??
                              (slot.index == 0 ? hostName : null),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Kamera/mikrofon/konuşma durumu: uzak katılımcı için TRTC bildirimcileri,
    // yerel için TrtcRoomManager alanları.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ?videoMap,
        ?audioMap,
        ?speakingN,
      ]),
      builder: (context, _) {
        final bool cameraOn;
        final bool micOn;
        final bool speaking;
        if (isSelf) {
          cameraOn = trtc?.cameraOn ?? slot.cameraOn;
          micOn = (trtc?.micOn ?? slot.micOn) && !slot.mutedByHost;
          speaking = micOn &&
              (speakingN?.value.contains(TrtcRoomManager.localSpeakingKey) ??
                  false);
        } else {
          final rid = remoteId;
          cameraOn = slot.cameraOn &&
              (rid == null || (videoMap?.value[rid] ?? true));
          micOn = !slot.mutedByHost &&
              (rid == null || (audioMap?.value[rid] ?? true));
          speaking = rid != null && (speakingN?.value.contains(rid) ?? false);
        }
        return body(cameraOn, micOn, speaking);
      },
    );
  }

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  Widget _emptySlot() {
    return GestureDetector(
      onTap: onInvite,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              onInvite != null ? 'Davet et' : 'Boş',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraOffPlaceholder(String name, String? avatar) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1450), Color(0xFF120A24)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white12,
              backgroundImage:
                  avatar?.isNotEmpty == true ? canlifalImageProvider(avatar!) : null,
              child: avatar?.isNotEmpty == true
                  ? null
                  : const Icon(Icons.person_rounded,
                      color: Colors.white54, size: 34),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _namePill(String name, String? avatar) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
          color: Colors.black.withValues(alpha: 0.4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 9,
                backgroundColor: Colors.white24,
                backgroundImage: avatar?.isNotEmpty == true
                    ? canlifalImageProvider(avatar!)
                    : null,
                child: avatar?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_rounded,
                        size: 11, color: Colors.white70),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micDot(bool micOn) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: micOn
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0xFFE11D48).withValues(alpha: 0.9),
      ),
      child: Icon(
        micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          color: Colors.black.withValues(alpha: 0.4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
