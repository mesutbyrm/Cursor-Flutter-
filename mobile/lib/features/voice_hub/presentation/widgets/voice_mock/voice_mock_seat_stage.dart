import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/cosmetics/presentation/providers/cosmetics_providers.dart';
import 'package:canlifal_social/features/cosmetics/presentation/widgets/cosmetic_mic_frame_ring.dart';
import 'package:canlifal_social/features/gifts/presentation/widgets/seat_gift_badge.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../domain/entities/voice_room_seat_slot.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_seat_gift_totals_provider.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_seat_capacity.dart';
import '../../utils/voice_room_seat_layout.dart';
import '../../utils/voice_seat_snapshot.dart';
import '../premium_2026/voice_seat_avatar_frame.dart';
import '../premium_2026/voice_seat_gift_flash_stack.dart';

/// Başlangıçta görünen koltuk sayısı (oda sahibi dahil).
const int kVoiceMockBaseVisibleSeats = 8;

/// Misafir koltuk numaraları: ilk 8 koltuk (sahip dahil) görünür; görünen
/// misafir koltukları dolunca bir tane daha açılır (en fazla 10) + dolu admin
/// koltuğu (11).
List<int> voiceMockGuestSeatNumbers({
  required VoiceRoomEntity room,
  required List<VoiceRoomSeatSlot> seatSlots,
  required List<ChatRoomPresence> presence,
  int? configuredSeatCount,
}) {
  final micSeats = resolveVoiceRoomSeatCount(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  if (micSeats <= 1) return const [];
  final cap = micSeats > 10 ? 10 : micSeats;
  final layout = VoiceRoomSeatLayout(
    room: room,
    presence: presence,
    seatSlots: seatSlots,
  ).build();
  bool occupied(int n) => layout[n] != null;

  var visible = math.min(cap, kVoiceMockBaseVisibleSeats);
  // Görünen tüm misafir koltukları doluysa bir koltuk daha aç.
  while (visible < cap &&
      [for (var n = 2; n <= visible; n++) n].every(occupied)) {
    visible++;
  }
  final nums = <int>[
    for (var i = 2; i <= visible; i++) i,
    // Daha ileri bir koltukta oturan varsa gizlenmesin.
    for (var i = visible + 1; i <= cap; i++)
      if (occupied(i)) i,
  ];
  final adminSeat = voiceRoomAdminSeatIndex(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  if (adminSeat != null && occupied(adminSeat)) nums.add(adminSeat);
  return nums;
}

/// Mockup koltuk sahnesi — sol üstte büyük oda sahibi, 4 sütunlu ızgara.
class VoiceMockSeatStage extends StatelessWidget {
  const VoiceMockSeatStage({
    super.key,
    required this.roomKey,
    required this.room,
    this.seatSlots = const [],
    this.presence = const [],
    this.configuredSeatCount,
    this.djUserIds = const [],
    this.speakingUserIds = const {},
    this.onSeatTap,
    this.onSeatLongPress,
    this.trtc,
    this.trtcReady = false,
    this.selfUserId,
    this.remoteTrtcUserId,
  });

  final String roomKey;
  final VoiceRoomEntity room;
  final List<VoiceRoomSeatSlot> seatSlots;
  final List<ChatRoomPresence> presence;
  final int? configuredSeatCount;
  final List<String> djUserIds;
  final Set<String> speakingUserIds;
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;
  final void Function(int internalSeatIndex)? onSeatLongPress;
  final TrtcRoomManager? trtc;
  final bool trtcReady;
  final String? selfUserId;
  final String? remoteTrtcUserId;

  @override
  Widget build(BuildContext context) {
    final guests = voiceMockGuestSeatNumbers(
      room: room,
      seatSlots: seatSlots,
      presence: presence,
      configuredSeatCount: configuredSeatCount,
    );
    // İlk satır: sahip + 3 misafir; sonrakiler 4'erli.
    final rows = <List<int>>[];
    var i = 0;
    rows.add(guests.take(3).toList());
    i = math.min(3, guests.length);
    while (i < guests.length) {
      rows.add(guests.sublist(i, math.min(i + 4, guests.length)));
      i += 4;
    }

    Widget cell(int seat, {required bool host}) => VoiceMockStageSeat(
          roomKey: roomKey,
          room: room,
          seatIndex: seat,
          isHost: host,
          djUserIds: djUserIds,
          speakingUserIds: speakingUserIds,
          onSeatTap: onSeatTap,
          onSeatLongPress: onSeatLongPress,
          trtc: trtc,
          trtcReady: trtcReady,
          selfUserId: selfUserId,
          remoteTrtcUserId: remoteTrtcUserId,
        );

    Widget rowOf(List<Widget> cells, {int slots = 4}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < slots; c++)
              Expanded(
                child: c < cells.length
                    ? Center(child: cells[c])
                    : const SizedBox.shrink(),
              ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          rowOf([
            cell(1, host: true),
            for (final s in rows.first) cell(s, host: false),
          ]),
          for (var r = 1; r < rows.length; r++) ...[
            const SizedBox(height: 6),
            rowOf([for (final s in rows[r]) cell(s, host: false)]),
          ],
        ],
      ),
    );
  }
}

/// Tek koltuk — yalnızca kendi snapshot'ı değişince rebuild.
class VoiceMockStageSeat extends ConsumerWidget {
  const VoiceMockStageSeat({
    super.key,
    required this.roomKey,
    required this.room,
    required this.seatIndex,
    required this.isHost,
    this.djUserIds = const [],
    this.speakingUserIds = const {},
    this.onSeatTap,
    this.onSeatLongPress,
    this.trtc,
    this.trtcReady = false,
    this.selfUserId,
    this.remoteTrtcUserId,
  });

  final String roomKey;
  final VoiceRoomEntity room;
  final int seatIndex;
  final bool isHost;
  final List<String> djUserIds;
  final Set<String> speakingUserIds;
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;
  final void Function(int internalSeatIndex)? onSeatLongPress;
  final TrtcRoomManager? trtc;
  final bool trtcReady;
  final String? selfUserId;
  final String? remoteTrtcUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(
      voiceRoomLiveProvider(roomKey).select(
        (live) => VoiceSeatSnapshot.fromLive(
          room: room,
          live: live,
          seatIndex: seatIndex,
        ),
      ),
    );
    final user = snap.user;
    final micOn = user == null ? true : (snap.micOpen ?? user.micOpen);
    final isSelf = user != null && selfUserId != null && user.id == selfUserId;
    final micCosmetic =
        isSelf ? ref.watch(resolvedMicrophoneFrameProvider) : null;
    final gift = user == null
        ? null
        : ref.watch(
            voiceSeatGiftTotalsProvider.select(
              (m) => selectSeatGiftAggregate(
                m,
                userId: user.id,
                displayName: user.displayName,
              ),
            ),
          );
    final canHub = AdminUserHubLauncher.canOpen(ref.watch(staffAccessProvider));
    final key = (roomKey.isNotEmpty ? roomKey : room.apiRoomKey).trim();

    final seat = VoiceMockSeat(
      seatIndex: seatIndex,
      isHost: isHost,
      user: user,
      locked: snap.locked,
      micOpen: micOn,
      speaking: snap.isSpeaking(extraSpeakingIds: speakingUserIds),
      isRoomDj: user != null &&
          (djUserIds.contains(user.id) || room.djUserIds.contains(user.id)),
      giftCoins: gift?.totalCoins ?? 0,
      micCosmetic: micCosmetic,
      flash: user != null && key.isNotEmpty
          ? VoiceSeatGiftFlashStack(
              roomKey: key,
              userId: user.id,
              displayName: user.displayName,
            )
          : null,
      onTap: () => onSeatTap?.call(seatIndex, user),
      onLongPress: user == null
          ? () => onSeatLongPress?.call(seatIndex)
          : canHub
              ? () => AdminUserHubLauncher.open(context, userId: user.id)
              : null,
    );
    if (user == null) return seat;
    return AdminUserHubLauncher.wrap(
      context: context,
      ref: ref,
      userId: user.id,
      onTap: () => onSeatTap?.call(seatIndex, user),
      child: seat,
    );
  }
}

String _compact(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

/// Saf görünüm — koltuk numarası, mikrofon rozeti, isim ve hediye değeri.
class VoiceMockSeat extends StatelessWidget {
  const VoiceMockSeat({
    super.key,
    required this.seatIndex,
    required this.isHost,
    required this.user,
    required this.locked,
    required this.micOpen,
    required this.speaking,
    required this.isRoomDj,
    required this.giftCoins,
    this.micCosmetic,
    this.flash,
    this.onTap,
    this.onLongPress,
  });

  final int seatIndex;
  final bool isHost;
  final ChatRoomPresence? user;
  final bool locked;
  final bool micOpen;
  final bool speaking;
  final bool isRoomDj;
  final int giftCoins;
  final dynamic micCosmetic;
  final Widget? flash;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double _pad = 10;

  @override
  Widget build(BuildContext context) {
    final size = isHost ? 56.0 : 52.0;
    final box = size + _pad;
    final u = user;

    Widget disc;
    if (u == null) {
      disc = _EmptyDisc(size: size, locked: locked);
    } else {
      Widget avatar = VoiceSeatAvatarFrame(
        imageUrl: u.image,
        size: size,
        role: SeatAvatarRoleResolver.resolve(
          user: u,
          isHost: isHost,
          isRoomDj: isRoomDj,
        ),
        speaking: speaking,
        micOpen: micOpen,
      );
      if (micCosmetic != null) {
        avatar = CosmeticMicFrameRing(
          item: micCosmetic,
          size: size,
          micOpen: micOpen,
          child: avatar,
        );
      }
      disc = avatar;
    }

    final wide = box;
    final avatarArea = SizedBox(
      width: wide,
      height: box + (isHost ? 6 : 4),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(top: 6, child: SizedBox(width: box, height: box, child: Center(child: disc))),
          if (u != null && isHost)
            const Positioned(
              top: -6,
              child: Text('👑', style: TextStyle(fontSize: 22)),
            )
          else if (u != null)
            Positioned(
              top: 0,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 17,
                color: VoiceRoomTokens.gold,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          // Koltuk numarası yalnızca BOŞ koltukta görünür; oturan varsa kaybolur.
          if (!isHost && u == null)
            Positioned(
              bottom: -2,
              child: _NumberBadge(seatIndex),
            ),
          if (isHost && u != null)
            Positioned(
              bottom: 12,
              right: (wide - box) / 2 + 2,
              child: _MicBadge(open: micOpen, host: true),
            )
          else if (u != null)
            Positioned(
              bottom: 10,
              right: (box - size) / 2 + 2,
              child: _MicBadge(open: micOpen),
            ),
          if (flash != null)
            Positioned(top: box * 0.3, child: IgnorePointer(child: flash!)),
        ],
      ),
    );

    final Widget label;
    if (isHost) {
      label = Text(
        u?.displayName ?? 'Boş',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFFE082),
          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
        ),
      );
    } else if (u == null) {
      label = Text(
        locked ? 'Kilitli' : 'Koltuk Aç',
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: locked ? 0.45 : 0.85),
        ),
      );
    } else {
      label = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            u.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: micOpen ? Colors.white : Colors.white60,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
          SizedBox(
            height: 18,
            child: giftCoins > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        _compact(giftCoins),
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFE082),
                          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      );
    }

    return Semantics(
      button: onTap != null,
      label: u == null
          ? (locked ? 'Koltuk $seatIndex, kilitli' : 'Koltuk $seatIndex, boş')
          : '${isHost ? 'Oda sahibi' : 'Koltuk $seatIndex'}, ${u.displayName}',
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: isHost ? wide + 4 : box + 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [avatarArea, label],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.n);

  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xE6140A22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
      ),
      child: Text(
        '$n',
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MicBadge extends StatelessWidget {
  const _MicBadge({required this.open, this.host = false});

  final bool open;
  final bool host;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: host
            ? const Color(0xFFB832FF)
            : const Color(0xE6140A22),
        border: Border.all(
          color: host ? Colors.white : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: Icon(
        open ? Icons.mic_rounded : Icons.mic_off_rounded,
        size: 13,
        color: open ? Colors.white : const Color(0xFFFCA5A5),
      ),
    );
  }
}

class _EmptyDisc extends StatelessWidget {
  const _EmptyDisc({required this.size, required this.locked});

  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: locked ? 0.3 : 0.6);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DashedRingPainter(color),
        child: Center(
          child: Icon(
            locked ? Icons.lock_rounded : Icons.add_rounded,
            size: size * 0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final r = size.width / 2 - 1;
    // Mockup: boş koltuk kesikli değil, ince düz halka.
    canvas.drawCircle(size.center(Offset.zero), r, paint);
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

