import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../feed/presentation/widgets/discover/discover_background.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import '../../trtc/presentation/trtc_room_manager.dart';

/// Sesli sohbet odası — Tencent TRTC (mikrofon aktif).
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
  var _speakerOn = true;

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
    await _trtc.leave();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _trtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final room = widget.room;

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: top + 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: _leave,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          room.nameTr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        if (room.ownerName != null)
                          Text(
                            room.ownerName!,
                            style: const TextStyle(
                              color: AppDesign.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_joined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesign.onlineGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppDesign.onlineGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: AppDesign.onlineGreen,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ses açık',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _joining
                  ? const DiscoverAccentLoader()
                  : _error != null
                      ? DiscoverEmptyState(
                          icon: Icons.headset_off_rounded,
                          message: _error!,
                          actionLabel: 'Tekrar dene',
                          action: () {
                            setState(() {
                              _joining = true;
                              _error = null;
                            });
                            _joinRoom();
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              ProfileGlass(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      room.icon ?? '💬',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Sesli sohbete bağlandın',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      room.descTr ?? 'Mikrofonun açık; konuşmaya başlayabilirsin.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppDesign.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        UserAvatar(
                                          url: null,
                                          radius: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${room.onlineCount} çevrimiçi',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const Text(
                                              'Tencent RTC ses odası',
                                              style: TextStyle(
                                                color: AppDesign.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _VoiceControl(
                                    icon: _micOn
                                        ? Icons.mic_rounded
                                        : Icons.mic_off_rounded,
                                    label: _micOn ? 'Mik açık' : 'Mik kapalı',
                                    active: _micOn,
                                    onTap: () {
                                      final next = !_micOn;
                                      _trtc.setMicEnabled(next);
                                      setState(() => _micOn = next);
                                    },
                                  ),
                                  _VoiceControl(
                                    icon: Icons.volume_up_rounded,
                                    label: 'Hoparlör',
                                    active: _speakerOn,
                                    onTap: () =>
                                        setState(() => _speakerOn = !_speakerOn),
                                  ),
                                  _VoiceControl(
                                    icon: Icons.call_end_rounded,
                                    label: 'Ayrıl',
                                    active: false,
                                    color: AppDesign.liveRed,
                                    onTap: _leave,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceControl extends StatelessWidget {
  const _VoiceControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppDesign.accentPink : AppDesign.textMuted);
    return Column(
      children: [
        Material(
          color: c.withValues(alpha: 0.2),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: c, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
