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
import 'providers/chat_room_providers.dart';
import 'widgets/voice_room/voice_room_action_row.dart';
import 'widgets/voice_room/voice_room_announcement.dart';
import 'widgets/voice_room/voice_room_bottom_bar.dart';
import 'widgets/voice_room/voice_room_chat_panel.dart';
import 'widgets/voice_room/voice_room_seats_panel.dart';
import 'widgets/voice_room/voice_room_top_bar.dart';

/// Sesli sohbet odası — web neon düzeni + TRTC ses + canlifal.com API.
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
  var _announcementVisible = true;

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

  String _latestSystemJoin(List<ChatRoomMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].kind == ChatMessageKind.systemJoin) {
        return messages[i].content;
      }
    }
    final owner = widget.room.ownerName ?? 'Oda sahibi';
    return '$owner sohbet odasına katıldı! 🎤';
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final live = ref.watch(voiceRoomLiveProvider(room));
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        ref.watch(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final online = live.presence.isNotEmpty
        ? live.presence.length
        : room.displayOnline;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isOwner = user != null && _isRoomOwner(user.id, user.username);
    final speakingId = _micOn ? user?.id : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                      child: VoiceRoomTopBar(
                        room: room,
                        onlineCount: online,
                        isCurrentUserOwner: isOwner,
                        onBack: _leave,
                        onExit: _leave,
                        onShare: _shareRoom,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoiceRoomSeatsPanel(
                        room: room,
                        presence: live.presence,
                        speakingUserId: speakingId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            if (_announcementVisible)
                              VoiceRoomAnnouncement(
                                text: room.descTr?.trim().isNotEmpty == true
                                    ? room.descTr!.trim()
                                    : 'Sohbet odasına hoş geldiniz...',
                                onDismiss: () =>
                                    setState(() => _announcementVisible = false),
                              ),
                            if (_announcementVisible) const SizedBox(height: 6),
                            VoiceRoomSystemBanner(
                              message: _latestSystemJoin(live.messages),
                            ),
                            const SizedBox(height: 8),
                            VoiceRoomActionRow(
                              dj: live.dj,
                              onMusicTap: () {
                                final msg = live.dj.canPlayMusic
                                    ? 'DJ müziği odada çalıyor'
                                    : 'Müzik DJ sırasına bağlı — DJ paneli yakında';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: VoiceRoomChatPanel(
                                messages: live.messages,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    VoiceRoomBottomBar(
                      controller: _messageCtrl,
                      coinBalance: coins,
                      micOn: _micOn,
                      sending: live.sending,
                      onMicToggle: () {
                        final next = !_micOn;
                        _trtc.setMicEnabled(next);
                        setState(() => _micOn = next);
                      },
                      onSend: () {
                        final text = _messageCtrl.text;
                        _messageCtrl.clear();
                        ref
                            .read(voiceRoomLiveProvider(room).notifier)
                            .sendMessage(text);
                      },
                      onRefresh: () =>
                          ref.read(voiceRoomLiveProvider(room).notifier).refresh(),
                      onShare: _shareRoom,
                      onTopUp: () => context.push('/jeton-store'),
                      onGiftTap: () => context.push(
                            '/gift-send?roomId=${Uri.encodeComponent(room.id)}',
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgPurpleGlow, AppColors.background],
            ),
          ),
        ),
        if (url != null && url!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.55),
            colorBlendMode: BlendMode.darken,
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    AppColors.background.withValues(alpha: 0.92),
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
