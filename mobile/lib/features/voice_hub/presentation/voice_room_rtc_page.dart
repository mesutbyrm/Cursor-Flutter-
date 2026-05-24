import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import '../../trtc/presentation/trtc_room_manager.dart';
import '../domain/entities/chat_room_message.dart';
import '../domain/entities/chat_room_presence.dart';
import 'providers/chat_room_providers.dart';
import 'providers/voice_room_ui_provider.dart';
import 'sheets/voice_room_sheets.dart';
import 'theme/voice_room_tokens.dart';
import 'widgets/premium/voice_premium_chat.dart';
import 'widgets/premium/voice_premium_controls.dart';
import 'widgets/premium/voice_premium_header.dart';
import 'widgets/premium/voice_premium_stage.dart';

/// Premium sesli sohbet odası — TRTC + canlifal API + Clubhouse/Discord düzeni.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  final _trtc = TrtcRoomManager();
  final _messageCtrl = TextEditingController();
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

  @override
  void dispose() {
    _messageCtrl.dispose();
    _trtc.dispose();
    super.dispose();
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
      final isOwner = _isRoomOwner(user.id, user.username);
      await _trtc.join(
        credentials: cred,
        isHost: isOwner,
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
    if (mounted) context.go('/voice-rooms');
  }

  bool _isRoomOwner(String userId, String username) {
    final room = widget.room;
    final oid = room.ownerId;
    if (oid != null && oid.isNotEmpty && oid == userId) return true;
    final uname = username.trim().toLowerCase();
    final slug = room.slug.trim().toLowerCase();
    return uname.isNotEmpty && slug == uname;
  }

  void _shareRoom() {
    final slug = widget.room.slug;
    final url = '${Env.siteOrigin}/sohbet/$slug';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paylaşım linki kopyalandı: $url')),
    );
  }

  void _openUser(ChatRoomPresence user) {
    showVoiceUserProfileSheet(
      context,
      user: user,
      isOwner: _isRoomOwner(
        ref.read(authControllerProvider).valueOrNull?.id ?? '',
        ref.read(authControllerProvider).valueOrNull?.username ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final live = ref.watch(voiceRoomLiveProvider(room));
    final ui = ref.watch(voiceRoomUiProvider);
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        ref.watch(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final online = live.presence.isNotEmpty
        ? live.presence.length
        : room.displayOnline;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isOwner = user != null && _isRoomOwner(user.id, user.username);
    final speakingId = _micOn ? user?.id : null;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _RoomBackground(url: room.backgroundImageUrl),
            if (_joining)
              const Center(child: DiscoverAccentLoader())
            else if (!_joined)
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
              )
            else
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: VoicePremiumHeader(
                        room: room,
                        onlineCount: online,
                        isOwner: isOwner,
                        onBack: _leave,
                        onExit: _leave,
                        onShare: _shareRoom,
                        onAudience: () => showVoiceSpeakerListSheet(
                          context,
                          presence: live.presence,
                          room: room,
                          onUserTap: _openUser,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: VoicePremiumStage(
                          room: room,
                          presence: live.presence,
                          speakingUserId: speakingId,
                          onUserTap: _openUser,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: VoicePremiumChat(
                          messages: live.messages,
                          onUserTap: (id, name) {
                            ChatRoomPresence? p;
                            for (final e in live.presence) {
                              if (e.id == id) {
                                p = e;
                                break;
                              }
                            }
                            if (p != null) {
                              _openUser(p);
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoicePremiumMessageBar(
                        controller: _messageCtrl,
                        sending: live.sending,
                        onSend: () {
                          final text = _messageCtrl.text;
                          _messageCtrl.clear();
                          ref
                              .read(voiceRoomLiveProvider(room).notifier)
                              .sendMessage(text);
                        },
                        onGift: () =>
                            showPremiumVoiceGiftShop(context, ref, room: room),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoicePremiumControls(
                        micOn: _micOn,
                        headphonesOn: ui.headphonesOn,
                        onMic: () {
                          final next = !_micOn;
                          _trtc.setMicEnabled(next);
                          setState(() => _micOn = next);
                        },
                        onHeadphones: () => ref
                            .read(voiceRoomUiProvider.notifier)
                            .toggleHeadphones(),
                        onRequestSpeak: () => showVoiceRequestSpeakSheet(
                          context,
                          ref,
                          pending: ui.requestSpeakPending,
                        ),
                        onEffects: () => showVoiceEffectsSheet(context, ref),
                        onMore: () => showVoiceMoreMenuSheet(
                          context,
                          onSettings: () => showVoiceRoomSettingsSheet(
                            context,
                            ref,
                            isOwner: isOwner,
                          ),
                          onSpeakers: () => showVoiceSpeakerListSheet(
                            context,
                            presence: live.presence,
                            room: room,
                            onUserTap: _openUser,
                          ),
                          onShare: _shareRoom,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 8),
                      child: Row(
                        children: [
                          Text(
                            '💎 $coins jeton',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: AppColors.diamondBlue,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/jeton-store'),
                            child: const Text('Jeton yükle'),
                          ),
                          TextButton(
                            onPressed: () => ref
                                .read(voiceRoomLiveProvider(room).notifier)
                                .refresh(),
                            child: const Text('Yenile'),
                          ),
                        ],
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

class _RoomBackground extends StatelessWidget {
  const _RoomBackground({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: VoiceRoomTokens.roomGradient)),
        if (url != null && url!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.6),
            colorBlendMode: BlendMode.darken,
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VoiceRoomTokens.neonPurple.withValues(alpha: 0.12),
                    VoiceRoomTokens.bgDeep.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
