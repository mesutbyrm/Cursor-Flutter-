import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import '../../trtc/presentation/trtc_room_manager.dart';
import 'widgets/voice_room_seat_grid.dart';

/// Sesli sohbet odası — web koltuk düzeni + Tencent TRTC ses.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  final _trtc = TrtcRoomManager();
  var _joining = true;
  var _joined = false;
  String? _error;
  var _micOn = true;
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
  }

  Future<void> _joinRoom() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      setState(() {
        _joining = false;
        _error = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    if (!_trtc.isSupported) {
      setState(() {
        _joining = false;
        _error = 'Sesli oda bu platformda desteklenmiyor';
      });
      return;
    }

    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: widget.room.id,
          );
      await _trtc.join(
        credentials: cred,
        isHost: false,
        audioOnly: true,
      );
      if (mounted) {
        setState(() {
          _joining = false;
          _joined = true;
          _micOn = _trtc.micOn;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = ApiException.userMessage(e);
        });
      }
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _trtc.leave();
    if (mounted) context.go('/live');
  }

  @override
  void dispose() {
    _trtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final room = widget.room;
    final user = ref.watch(authControllerProvider).valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: AppDesign.bgBase,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_joined)
              VoiceRoomSeatGrid(
                roomIcon: room.icon ?? '💬',
                roomName: room.nameTr,
                backgroundUrl: room.backgroundImageUrl,
                centerAvatarUrl: user?.avatarUrl ?? room.ownerAvatarUrl,
                recentAvatars: room.recentUserAvatars,
                speakingUserIndex: _micOn ? 0 : null,
              )
            else if (_joining)
              const Center(child: DiscoverAccentLoader())
            else
              Center(
                child: DiscoverEmptyState(
                  icon: Icons.headset_off_rounded,
                  message: _error ?? 'Bağlantı kurulamadı',
                  actionLabel: 'Tekrar dene',
                  action: () {
                    setState(() {
                      _joining = true;
                      _error = null;
                    });
                    _joinRoom();
                  },
                ),
              ),
            if (_joined)
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, top > 0 ? 4 : 8, 8, 0),
                      child: _VoiceTopBar(
                        room: room,
                        onBack: _leave,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            bottom + 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border(
                              top: BorderSide(
                                color: AppDesign.accentPurple
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _VoiceFab(
                                icon: _micOn
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                label: _micOn ? 'Mik açık' : 'Kapalı',
                                color: _micOn
                                    ? AppDesign.accentPink
                                    : AppDesign.textMuted,
                                onTap: () {
                                  final next = !_micOn;
                                  _trtc.setMicEnabled(next);
                                  setState(() => _micOn = next);
                                },
                              ),
                              _VoiceFab(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Sohbet',
                                color: AppDesign.accentCyan,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Oda sohbeti web ile senkron — yakında',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _VoiceFab(
                                icon: Icons.call_end_rounded,
                                label: 'Ayrıl',
                                color: AppDesign.liveRed,
                                onTap: _leave,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTopBar extends StatelessWidget {
  const _VoiceTopBar({required this.room, required this.onBack});

  final VoiceRoomEntity room;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 18,
      blur: 12,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(room.icon ?? '💬', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.nameTr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${room.displayOnline} çevrimiçi',
                  style: const TextStyle(
                    color: AppDesign.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppDesign.onlineGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: AppDesign.onlineGreen),
                SizedBox(width: 4),
                Text(
                  'CANLI',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceFab extends StatelessWidget {
  const _VoiceFab({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
