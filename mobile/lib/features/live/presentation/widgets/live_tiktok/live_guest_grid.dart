import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

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

    if (layout == LiveGuestLayout.duo) {
      return Row(
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

  int get _displayJeton =>
      slot.isHost || slot.index == 0 ? hostJetonEarned : slot.jetonEarned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget child;
    if (slot.isHost || slot.index == 0) {
      child = trtc != null
          ? TrtcLocalVideoView(key: localPreviewKey, manager: trtc!)
          : _placeholder(hostName ?? 'Sen', hostAvatarUrl);
    } else if (remoteUserId != null && trtc != null) {
      child = TrtcRemoteVideoView(
        key: ValueKey(remoteUserId),
        manager: trtc!,
        userId: remoteUserId!,
      );
    } else if (slot.isEmpty) {
      return _emptySlot();
    } else {
      child = _placeholder(slot.displayName ?? 'Konuk', null);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (pinned)
            Positioned(
              top: 6,
              left: 6,
              child: _badge(Icons.push_pin_rounded, 'Sabit'),
            ),
          if (slot.mutedByHost)
            Positioned(
              top: 6,
              right: 6,
              child: _badge(Icons.mic_off_rounded, 'Sessiz'),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            right: isHost && slot.index > 0 && onAction != null ? 72 : 6,
            child: _badge(
              Icons.person_rounded,
              slot.displayName ?? hostName ?? 'Yayıncı',
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: LiveSeatGiftFlashStack(
              userId: slot.userId ?? (slot.index == 0 ? null : remoteUserId),
              displayName: slot.displayName ?? (slot.index == 0 ? hostName : null),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Center(
              child: SeatGiftBadge(
                compact: true,
                receiverName: slot.displayName ?? hostName ?? 'Yayıncı',
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
          if (_displayJeton > 0)
            Positioned(
              left: 6,
              top: 6,
              child: _badge(Icons.monetization_on_rounded, '$_displayJeton'),
            ),
          if (isHost && slot.index > 0 && onAction != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniBtn(Icons.push_pin_outlined, () => onAction!('pin')),
                  _miniBtn(Icons.mic_off_outlined, () => onAction!('mute')),
                  _miniBtn(Icons.videocam_off_outlined, () => onAction!('cam')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptySlot() {
    return GestureDetector(
      onTap: onInvite,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
              'Davet et',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String name, String? avatar) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar?.isNotEmpty == true)
              CircleAvatar(
                radius: 24,
                backgroundImage: canlifalImageProvider(avatar!),
              )
            else
              const Icon(Icons.person_rounded, color: Colors.white54, size: 40),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: Colors.black.withValues(alpha: 0.45),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
