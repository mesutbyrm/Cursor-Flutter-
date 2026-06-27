import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_audio_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_sheets.dart';
import '../utils/voice_room_permissions.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../utils/kick_strike_ui.dart';
import 'voice_room_basic_realtime_feed.dart';
import '../widgets/voice_room_error_boundary.dart';

/// Aşama 1 — oda listesi, giriş/çıkış, mikrofon, hoparlör, katılımcılar, oda sahibi.
class VoiceRoomBasicPage extends ConsumerStatefulWidget {
  const VoiceRoomBasicPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomBasicPage> createState() => _VoiceRoomBasicPageState();
}

class _VoiceRoomBasicPageState extends ConsumerState<VoiceRoomBasicPage> {
  VoiceRoomAudioCoordinator? _audio;
  String? _pinnedLiveRoomKey;
  var _audioJoining = true;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _isMicMuted = true;
  var _leaving = false;

  String get _liveRoomKey {
    final pinned = _pinnedLiveRoomKey?.trim();
    if (pinned != null && pinned.isNotEmpty) return pinned;
    final key = _effectiveRoom().apiRoomKey;
    if (key.isNotEmpty) _pinnedLiveRoomKey = key;
    return key.isNotEmpty ? key : widget.room.apiRoomKey;
  }

  VoiceRoomEntity _effectiveRoom() {
    final w = widget.room;
    final rooms = ref.read(voiceRoomsProvider).valueOrNull;
    if (rooms == null) return w;
    for (final r in rooms) {
      if (r.id == w.id || r.apiRoomKey == w.apiRoomKey) return r;
    }
    return w;
  }

  @override
  void initState() {
    super.initState();
    if (widget.room.apiRoomKey.isNotEmpty) {
      _pinnedLiveRoomKey = widget.room.liveKey;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.room.apiRoomKey.isEmpty) {
        unawaited(ref.read(voiceRoomsProvider.future));
      }
      unawaited(_joinAudio());
    });
  }

  @override
  void dispose() {
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      unawaited(
        audio.leave().whenComplete(() {
          try {
            audio.dispose();
          } catch (_) {}
        }),
      );
    }
    super.dispose();
  }

  Future<UserEntity?> _waitForAuth() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future).timeout(
            const Duration(seconds: 12),
          );
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  bool _isRoomOwner(UserEntity user, VoiceRoomEntity room) {
    final oid = room.ownerId;
    if (oid != null && oid.isNotEmpty && oid == user.id) return true;
    final uname = user.username.trim().toLowerCase();
    final slug = room.slug.trim().toLowerCase();
    return uname.isNotEmpty && slug == uname;
  }

  Future<void> _joinAudio() async {
    if (!mounted) return;
    setState(() {
      _audioJoining = true;
      _audioError = null;
    });

    final user = await _waitForAuth();
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _audioJoining = false;
        _loginError = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    var room = _effectiveRoom();
    if (room.apiRoomKey.isEmpty && widget.room.apiRoomKey.isNotEmpty) {
      room = widget.room;
      _pinnedLiveRoomKey = room.liveKey;
    }
    if (room.apiRoomKey.isEmpty) {
      setState(() {
        _audioJoining = false;
        _audioError = 'Oda bilgisi yüklenemedi';
      });
      return;
    }

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      setState(() {
        _audioJoining = false;
        _audioError = 'Ses bu cihazda desteklenmiyor';
      });
      return;
    }

    try {
      final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        server: live.serverPermissions,
      );
      await _audio!.join(
        trtcRoomId: room.trtcRoomId,
        userId: user.id,
        isHost: _isRoomOwner(user, room) || perms.isSiteAdmin,
        liveKitRemote: ref.read(liveKitRemoteProvider),
        trtcRemote: ref.read(trtcRemoteProvider),
      );
      if (!mounted) return;
      unawaited(VoiceRoomMusicAudioSession.activateForPlayback());
      _audio!.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
      setState(() {
        _audioJoining = false;
        _audioReady = true;
        _isMicMuted = !_audio!.micOn;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _audioJoining = false;
        _audioError = ApiException.userMessage(e);
      });
    }
  }

  void _toggleMic() {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    _audio!.setMicEnabled(!muted);
    setState(() => _isMicMuted = muted);
  }

  void _toggleSpeaker() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
    setState(() {});
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    _leaving = true;

    final liveCtrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
    final audio = _audio;
    _audio = null;

    unawaited(liveCtrl.leaveRoomSession(source: 'basic_leave'));
    if (audio != null) {
      unawaited(
        audio.leave().whenComplete(() {
          try {
            audio.dispose();
          } catch (_) {}
        }),
      );
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/voice-rooms');
    }
    _leaving = false;
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odadan çık'),
        content: const Text('Sesli sohbetten ayrılmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) await _leaveRoom();
  }

  ChatRoomPresence? _resolveOwner(
    VoiceRoomEntity room,
    List<ChatRoomPresence> presence,
  ) {
    final ownerId = room.ownerId;
    if (ownerId != null) {
      for (final p in presence) {
        if (p.id == ownerId) return p;
      }
    }
    final name = room.ownerName?.trim();
    if (name != null && name.isNotEmpty) {
      return ChatRoomPresence(
        id: ownerId ?? 'owner',
        name: name,
        image: room.ownerAvatarUrl,
        chatRole: 'owner',
        seatIndex: 1,
      );
    }
    return null;
  }

  void _openParticipants(VoiceRoomEntity room, List<ChatRoomPresence> presence) {
    showVoiceSpeakerListSheet(
      context,
      presence: presence,
      room: room,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomKey = _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id;
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    final live = ref.watch(voiceRoomLiveProvider(_liveRoomKey));
    final ui = ref.watch(voiceRoomUiProvider);
    final room = _effectiveRoom();
    final online = live.onlineCountFor(room);
    final owner = _resolveOwner(room, live.presence);
    final speakerOn = ui.headphonesOn;

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      if (!mounted) return;

      final toast = next.moderationToast;
      if (toast != null && toast != prev?.moderationToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toast), duration: const Duration(seconds: 4)),
        );
      }

      final banner = next.enterBanner;
      if (banner != null && banner != prev?.enterBanner) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(banner),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final kick = next.kickStrikeWarning;
      if (kick != null && kick != prev?.kickStrikeWarning) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(KickStrikeUi.titleFor(next.kickStrikeCount)),
              content: Text(kick),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
        );
      }

      if (next.realtimeEvents.length > (prev?.realtimeEvents.length ?? 0)) {
        final latest = next.realtimeEvents.first;
        if (latest.kind == VoiceRoomRealtimeKind.moderation &&
            latest.message.toLowerCase().contains('yasaklandınız')) {
          unawaited(_leaveRoom());
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.displayTitle, style: const TextStyle(fontSize: 16)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: live.sseConnected ? Colors.greenAccent : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    live.sseConnected ? 'Canlı (SSE)' : 'Bağlanıyor…',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _openParticipants(room, live.presence),
              icon: const Icon(Icons.people_outline_rounded, size: 20),
              label: Text('$online'),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (live.roomMuted)
              _Banner(message: 'Oda susturulmuş (yalnızca yetkililer konuşabilir)'),
            if (_loginError != null)
              _Banner(message: _loginError!, isError: true),
            if (_audioError != null)
              _Banner(message: _audioError!, isError: true),
            if (_audioJoining)
              const LinearProgressIndicator(minHeight: 2),
            if (live.loading && live.presence.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: _OwnerCard(owner: owner, room: room),
              ),
              VoiceRoomBasicParticipantStrip(
                presence: live.presence,
                ownerId: room.ownerId,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () => _openParticipants(room, live.presence),
                  icon: const Icon(Icons.group_rounded),
                  label: Text('Katılımcılar ($online)'),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          'Canlı olaylar',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      VoiceRoomBasicRealtimeFeed(events: live.realtimeEvents),
                    ],
                  ),
                ),
              ),
              if (live.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    live.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ControlButton(
                    icon: _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMicMuted ? 'Mic kapalı' : 'Mic açık',
                    active: !_isMicMuted,
                    onTap: _toggleMic,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ControlButton(
                    icon: speakerOn
                        ? Icons.volume_up_rounded
                        : Icons.hearing_disabled_rounded,
                    label: speakerOn ? 'Hoparlör' : 'Sessiz',
                    active: speakerOn,
                    onTap: _toggleSpeaker,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ControlButton(
                    icon: Icons.logout_rounded,
                    label: 'Çık',
                    active: false,
                    danger: true,
                    onTap: _confirmLeave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.room});

  final ChatRoomPresence? owner;
  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context) {
    final name = owner?.displayName ?? room.ownerName ?? 'Oda sahibi';
    final image = owner?.image ?? room.ownerAvatarUrl;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: image != null && image.isNotEmpty
                  ? CachedNetworkImageProvider(image)
                  : null,
              child: image == null || image.isEmpty
                  ? const Icon(Icons.star_rounded, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oda sahibi',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = danger
        ? scheme.errorContainer
        : active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final fg = danger
        ? scheme.onErrorContainer
        : active
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(message),
      ),
    );
  }
}

/// Rota sarmalayıcı — hata sınırı ile temel sayfa.
Widget voiceRoomBasicPageWithBoundary({
  required String roomId,
  required VoiceRoomEntity room,
}) {
  return VoiceRoomErrorBoundary(
    roomId: roomId,
    child: VoiceRoomBasicPage(room: room),
  );
}
