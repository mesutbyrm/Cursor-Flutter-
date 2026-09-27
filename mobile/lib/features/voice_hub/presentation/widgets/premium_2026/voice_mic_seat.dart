import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/cosmetics/presentation/providers/cosmetics_providers.dart';
import 'package:canlifal_social/features/cosmetics/presentation/widgets/cosmetic_mic_frame_ring.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/gifts/presentation/widgets/seat_gift_badge.dart';
import '../../providers/voice_seat_gift_totals_provider.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/vip_badge.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_seat_avatar_frame.dart';
import 'voice_seat_gift_flash_stack.dart';

/// Tek mikrofon koltuğu — boş, kilitli veya dolu.
///
/// Koltuk her durumda [boxWidth] × [footprintHeight] yer kaplar: hediye rozeti
/// avatarın alt kenarına, hediye bildirimi avatarın üstüne biner; böylece
/// uzun isim ya da gelen hediye koltuk ızgarasını taşırmaz.
class VoiceMicSeat extends ConsumerWidget {
  const VoiceMicSeat({
    super.key,
    this.user,
    required this.seatIndex,
    this.speaking = false,
    this.micOpen,
    this.size = 56,
    this.isHost = false,
    this.locked = false,
    this.room,
    this.roomKey,
    this.djUserIds = const [],
    this.onTap,
    this.onLongPress,
    this.trtc,
    this.trtcReady = false,
    this.selfUserId,
    this.remoteTrtcUserId,
  });

  final ChatRoomPresence? user;
  final int seatIndex;
  final bool speaking;
  /// null ise [ChatRoomPresence.micOpen] veya koltukta varsayılan açık.
  final bool? micOpen;
  final double size;
  final bool isHost;
  final bool locked;
  final VoiceRoomEntity? room;
  final String? roomKey;
  final List<String> djUserIds;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final TrtcRoomManager? trtc;
  final bool trtcReady;
  final String? selfUserId;
  final String? remoteTrtcUserId;

  /// Avatar çerçevesinin (neon halka + dalga payı) avatara eklediği genişlik.
  static const double framePad = 10;
  static const double _labelGap = 3;

  static double labelFontSize(double size) => size > 60 ? 11 : 10;

  static double _labelHeight(double size) =>
      (labelFontSize(size) * 1.3).ceilToDouble();

  /// Koltuğun kapladığı genişlik.
  static double boxWidth(double size) => size + framePad;

  /// Koltuğun kapladığı yükseklik (avatar + isim satırı).
  static double footprintHeight(double size) =>
      boxWidth(size) + _labelGap + _labelHeight(size);

  bool _resolveMicOpen(ChatRoomPresence u) => micOpen ?? u.micOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) {
      return _EmptySeat(
        seatIndex: seatIndex,
        size: size,
        locked: locked,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    final u = user!;
    final vipTier = VipTier.fromMembership(u.membership);
    final roleLabel = _roleLabel(u);
    final micOn = _resolveMicOpen(u);
    final isSelf = selfUserId != null && u.id == selfUserId;
    final micCosmetic =
        isSelf ? ref.watch(resolvedMicrophoneFrameProvider) : null;
    final box = boxWidth(size);
    final key = (roomKey ?? room?.apiRoomKey ?? room?.id ?? '').trim();

    Widget avatar = VoiceSeatAvatarFrame(
      imageUrl: u.image,
      size: size,
      role: SeatAvatarRoleResolver.resolve(
        user: u,
        isHost: isHost,
        isRoomDj:
            djUserIds.contains(u.id) || room?.djUserIds.contains(u.id) == true,
      ),
      speaking: speaking,
      micOpen: micOn,
    );

    if (micCosmetic != null) {
      avatar = CosmeticMicFrameRing(
        item: micCosmetic,
        size: size,
        micOpen: micOn,
        child: avatar,
      );
    }

    final name = u.displayName;
    final semantics = [
      isHost ? 'Oda sahibi' : 'Koltuk $seatIndex',
      name,
      if (speaking && micOn) 'konuşuyor',
      if (!micOn) 'mikrofon kapalı',
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semantics,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: box,
          height: footprintHeight(size),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  SizedBox.square(
                    dimension: box,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        avatar,
                        if (!isHost && roleLabel != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _Chip(
                              label: roleLabel,
                              gradient: micOn ? VoiceRoomTokens.neonRing : null,
                            ),
                          )
                        else if (!isHost && vipTier.isVip)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: VipBadge(tier: vipTier, compact: true),
                          ),
                        if (!isHost && seatIndex > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _Chip(label: '$seatIndex'),
                          ),
                        if (!micOn)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: _MicOffDot(size: size),
                          ),
                        Positioned(
                          bottom: -3,
                          left: -6,
                          right: -6,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SeatGiftBadge(
                              compact: true,
                              aggregate: ref.watch(
                                voiceSeatGiftTotalsProvider.select(
                                  (m) => selectSeatGiftAggregate(
                                    m,
                                    userId: u.id,
                                    displayName: name,
                                  ),
                                ),
                              ),
                              receiverName: name,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _labelGap),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: labelFontSize(size),
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: isHost
                          ? (micOn ? VoiceRoomTokens.gold : Colors.white54)
                          : (micOn ? Colors.white : Colors.white60),
                    ),
                  ),
                ],
              ),
              if (key.isNotEmpty)
                Positioned(
                  top: box * 0.3,
                  left: -box / 2,
                  right: -box / 2,
                  child: IgnorePointer(
                    child: Center(
                      child: VoiceSeatGiftFlashStack(
                        roomKey: key,
                        userId: u.id,
                        displayName: name,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sunucunun verdiği rol simgesi; yoksa yayıncı için "MOD".
///
/// Eskiden bunların ikisi de yoksa koltuk numarasından "Lv3" gibi sahte bir
/// seviye üretiliyordu — kullanıcı seviyesi sanılıyordu.
String? _roleLabel(ChatRoomPresence user) {
  final sym = user.roleSymbol?.trim();
  if (sym != null && sym.isNotEmpty && sym.length <= 6) return sym;
  if (user.isBroadcaster) return 'MOD';
  return null;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.gradient});

  final String label;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? const Color(0xCC111118) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          fontSize: 8,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MicOffDot extends StatelessWidget {
  const _MicOffDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xE6111118),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(
        Icons.mic_off_rounded,
        size: (size * 0.2).clamp(9.0, 14.0),
        color: const Color(0xFFFCA5A5),
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat({
    required this.seatIndex,
    required this.size,
    required this.locked,
    this.onTap,
    this.onLongPress,
  });

  final int seatIndex;
  final double size;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // Oda zemini temadan bağımsız koyu; renkler sabit (açık temada da okunur).
    final ring = locked
        ? Colors.white.withValues(alpha: 0.16)
        : VoiceRoomTokens.neonPurple.withValues(alpha: 0.45);
    return Semantics(
      button: onTap != null,
      label: locked
          ? 'Koltuk $seatIndex, kilitli'
          : 'Koltuk $seatIndex, boş. Oturmak için dokun',
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      // Kilitli koltuk da dokunulabilir: yetkiliye kilit menüsü açılır,
      // diğerlerine "Bu koltuk kilitli" bildirilir (dokunma işleyicisinde).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: VoiceMicSeat.boxWidth(size),
          height: VoiceMicSeat.footprintHeight(size),
          child: Column(
            children: [
              SizedBox.square(
                dimension: VoiceMicSeat.boxWidth(size),
                child: Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: locked ? 0.03 : 0.06),
                      border: Border.all(color: ring, width: 1.5),
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : Icons.mic_none_rounded,
                      color: Colors.white.withValues(alpha: locked ? 0.4 : 0.55),
                      size: size * 0.36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VoiceMicSeat._labelGap),
              Text(
                locked ? 'Kilitli' : '$seatIndex',
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: VoiceMicSeat.labelFontSize(size),
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: locked ? 0.4 : 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
