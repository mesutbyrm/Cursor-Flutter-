import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/live_guest_layout.dart';
import '../../../../agora/presentation/agora_room_manager.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';

/// TikTok tarzı misafir grid — 1/2/3/4 koltuk.
class LiveGuestGrid extends StatelessWidget {
  const LiveGuestGrid({
    super.key,
    required this.layout,
    required this.isHost,
    this.agora,
    this.trtc,
    this.localPreviewKey,
    this.hostAvatarUrl,
    this.hostName,
    this.remoteUserId,
    this.remoteUid,
    this.onInviteSlot,
  });

  final LiveGuestLayout layout;
  final bool isHost;
  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final Key? localPreviewKey;
  final String? hostAvatarUrl;
  final String? hostName;
  final String? remoteUserId;
  final int? remoteUid;
  final void Function(int slotIndex)? onInviteSlot;

  @override
  Widget build(BuildContext context) {
    if (layout == LiveGuestLayout.solo) {
      return _soloView();
    }
    return _gridView();
  }

  Widget _localVideo() {
    if (agora != null) {
      return AgoraLocalVideoView(key: localPreviewKey, manager: agora!);
    }
    if (trtc != null) {
      return TrtcLocalVideoView(key: localPreviewKey, manager: trtc!);
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _remoteVideo() {
    if (agora != null) {
      final uid = remoteUid ?? agora!.remoteUid;
      if (uid != null && uid > 0) {
        return AgoraRemoteVideoView(key: ValueKey(uid), manager: agora!, uid: uid);
      }
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

  Widget _soloView() {
    if (isHost && (agora != null || trtc != null)) {
      return _localVideo();
    }
    if ((remoteUid != null || remoteUserId != null) &&
        (agora != null || trtc != null)) {
      return _remoteVideo();
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _gridView() {
    final count = layout.seats;
    final cross = count <= 2 ? 1 : 2;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: cross == 1 ? 0.72 : 0.55,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i == 0 && isHost && (agora != null || trtc != null)) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _localVideo(),
          );
        }
        if (i == 1 && (remoteUid != null || remoteUserId != null)) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _remoteVideo(),
          );
        }
        return _emptySlot(i);
      },
    );
  }

  Widget _emptySlot(int index) {
    return GestureDetector(
      onTap: onInviteSlot == null ? null : () => onInviteSlot!(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index == 0 && hostAvatarUrl?.isNotEmpty == true)
              CircleAvatar(
                radius: 28,
                backgroundImage: CachedNetworkImageProvider(hostAvatarUrl!),
              )
            else
              Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 32,
              ),
            const SizedBox(height: 8),
            Text(
              index == 0 ? (hostName ?? 'Sen') : 'Misafir davet et',
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
}
