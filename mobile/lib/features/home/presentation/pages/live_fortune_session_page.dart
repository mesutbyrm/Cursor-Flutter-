import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/widgets/broadcast_room/live_room_video_background.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/entities/live_fortune_session_entity.dart';

/// Canlı fal video oturumu — TRTC + süre sayacı + sohbet.
class LiveFortuneSessionPage extends ConsumerStatefulWidget {
  const LiveFortuneSessionPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneSessionPage> createState() =>
      _LiveFortuneSessionPageState();
}

class _LiveFortuneSessionPageState extends ConsumerState<LiveFortuneSessionPage> {
  final _trtc = TrtcRoomManager();
  final _chat = TextEditingController();
  final _messages = <_ChatLine>[];
  var _rtcReady = false;
  String? _rtcError;
  var _leaving = false;
  late Duration _remaining;
  Timer? _tick;
  Key _localPreviewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: widget.session.durationMinutes);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) {
        unawaited(_onTimeUp());
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRtc());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _chat.dispose();
    _trtc.dispose();
    super.dispose();
  }

  Future<UserEntity?> _waitForAuth() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future);
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  Future<void> _joinRtc() async {
    final user = await _waitForAuth();
    if (user == null) {
      if (mounted) setState(() => _rtcError = 'Oturum için giriş gerekli');
      return;
    }
    if (!_trtc.isSupported) {
      if (mounted) setState(() => _rtcError = 'Video bu cihazda desteklenmiyor');
      return;
    }
    final isClient = widget.session.isClient;
    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: widget.session.trtcRoomId,
          );
      await _trtc.join(
        credentials: cred,
        isHost: !isClient,
        audioOnly: false,
        expectedAnchorUserId: isClient ? widget.session.anchorUserId : null,
      );
      if (mounted) setState(() => _rtcReady = true);
    } catch (e) {
      if (mounted) setState(() => _rtcError = ApiException.userMessage(e));
    }
  }

  Future<void> _onTimeUp() async {
    _tick?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seans süresi doldu')),
    );
    await _leave(silent: true);
  }

  String get _timerLabel {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _sendChat() {
    final t = _chat.text.trim();
    if (t.isEmpty) return;
    _chat.clear();
    setState(() {
      _messages.add(_ChatLine(user: 'Sen', text: t));
    });
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Seansı sonlandır?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Canlı fal oturumundan çıkmak istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _leave();
  }

  Widget _videoLayer() {
    if (!_rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const LiveRoomVideoBackground(),
          if (_rtcError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _rtcError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (!widget.session.isClient) {
      return TrtcLocalVideoView(key: _localPreviewKey, manager: _trtc);
    }
    final anchorId = widget.session.anchorUserId;
    return ValueListenableBuilder<String?>(
      valueListenable: _trtc.remoteAnchorUserIdNotifier,
      builder: (context, anchor, _) {
        final remoteId =
            (anchor != null && anchor.isNotEmpty) ? anchor : anchorId;
        if (remoteId.isNotEmpty) {
          return TrtcRemoteVideoView(
            key: ValueKey(remoteId),
            manager: _trtc,
            userId: remoteId,
          );
        }
        return const LiveRoomVideoBackground();
      },
    );
  }

  Future<void> _leave({bool silent = false}) async {
    if (_leaving) return;
    _leaving = true;
    await _trtc.leave();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/canli-falcilar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final teller = widget.session.teller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmEnd();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _videoLayer()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                    child: ProfileGlass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      borderRadius: 18,
                      blur: 12,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _confirmEnd,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teller.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00E676),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bağlı',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ProfileGlass(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            borderRadius: 12,
                            blur: 6,
                            child: Text(
                              _timerLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TopChip(
                            label: '+ Süre',
                            color: const Color(0xFFFFD54F),
                            foreground: Colors.black87,
                            onTap: () => openJetonStore(context, ref: ref),
                          ),
                          const SizedBox(width: 4),
                          _TopChip(
                            label: 'Bahşiş',
                            color: AppThemeColors.accentPink,
                            icon: Icons.card_giftcard_rounded,
                            onTap: () => openJetonStore(context, ref: ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ProfileGlass(
                      borderRadius: 16,
                      blur: 10,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Sohbet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 20,
                              ),
                            ],
                          ),
                          if (_messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Henüz mesaj yok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 72,
                              child: ListView.builder(
                                itemCount: _messages.length,
                                itemBuilder: (_, i) {
                                  final m = _messages[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${m.user}: ',
                                            style: const TextStyle(
                                              color: AppThemeColors.accentCyan,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                          TextSpan(
                                            text: m.text,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Mesaj yaz...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendChat(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: const Color(0xFFFFB300),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: _sendChat,
                                  borderRadius: BorderRadius.circular(14),
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ControlBtn(
                                icon: _trtc.cameraOn
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                onTap: _rtcReady
                                    ? () {
                                        if (_trtc.cameraOn) {
                                          _trtc.stopLocalPreview();
                                        } else {
                                          setState(() => _localPreviewKey = UniqueKey());
                                        }
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              _ControlBtn(
                                icon: _trtc.micOn
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                onTap: _rtcReady
                                    ? () {
                                        _trtc.setMicEnabled(!_trtc.micOn);
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              _ControlBtn(
                                icon: Icons.cameraswitch_rounded,
                                onTap: _rtcReady ? _trtc.switchCamera : null,
                              ),
                              _ControlBtn(
                                icon: Icons.call_end_rounded,
                                color: AppColors.liveRed,
                                onTap: _confirmEnd,
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
          ],
        ),
      ),
    );
  }
}

class _ChatLine {
  const _ChatLine({required this.user, required this.text});
  final String user;
  final String text;
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppThemeColors.accentPurple;
    return Material(
      color: c.withValues(alpha: color != null ? 1 : 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
