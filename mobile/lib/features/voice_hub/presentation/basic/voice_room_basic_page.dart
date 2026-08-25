import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../utils/kick_strike_ui.dart';
import '../widgets/voice_room_error_boundary.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/staff_roles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../../domain/voice_official_join.dart';
import '../../../gifts/presentation/sync/gift_event_listener.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_trtc_engine.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_audio_providers.dart';
import '../utils/voice_room_key_resolver.dart';
import '../providers/voice_session_phase_provider.dart';
import '../../domain/voice/voice_session_phase.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_commands_panel.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/voice_room_error_display.dart';
import '../utils/voice_room_speak_access.dart';
import '../utils/voice_room_session_exit.dart';
import '../utils/voice_room_leave_flow.dart';
import '../theme/voice_room_tokens.dart';
import '../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../widgets/premium/voice_gift_stage_overlays.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_entrance_overlay.dart';
import '../../../vip_gold/presentation/providers/user_room_profile_provider.dart';
import '../../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'voice_room_basic_moderation_section.dart';
import 'voice_room_basic_premium_section.dart';
import '../../music/presentation/widgets/music_search_picker_sheet.dart';
import '../sheets/music_mode_picker_sheet.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_music_submit.dart';
import '../sheets/voice_youtube_song_sheet.dart';
import '../sheets/voice_room_sheets.dart';
import '../../music/presentation/providers/room_music_providers.dart';
import '../../music/presentation/widgets/room_song_mini_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../sheets/voice_room_management_panel.dart';
import '../widgets/premium_2026/voice_live_action_bar_2026.dart';
import '../widgets/premium_2026/voice_live_header_2026.dart';
import '../widgets/premium_2026/voice_online_gift_box.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../widgets/voice_room/voice_room_center_music_panel.dart';
import '../widgets/voice_room/voice_room_music_background_layer.dart';
import '../widgets/voice_room/voice_room_video_close_bar.dart';
import '../widgets/voice_room/voice_room_music_queue_mini_card.dart';
import '../widgets/voice_room/voice_room_side_action_rail.dart';
import '../../../gifts/presentation/widgets/gift_battle_strip.dart';
import '../../../gifts/presentation/widgets/first_gifter_badge.dart';
import '../../../gifts/presentation/widgets/gift_goal_bar.dart';

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
  var _audioJoining = false;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _isMicMuted = true;
  var _leaving = false;
  var _leaveSessionStarted = false;
  var _forcedExitHandled = false;
  var _musicSearchOpen = false;
  final _messageCtrl = TextEditingController();
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
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
    final resolved = VoiceRoomKeyResolver.resolveFromKnownRooms(w.liveKey, rooms);
    if (resolved != null) {
      for (final r in rooms) {
        if (r.id == resolved) return r;
      }
    }
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
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).ensureActiveSession();
      _startPremiumRealtime(ref.read(authControllerProvider).valueOrNull);
      unawaited(_joinAudioBackground());
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    ref.read(pkBattleRemoteProvider.notifier).clear();
    final liveKey = _pinnedLiveRoomKey;
    if (!_leaveSessionStarted &&
        liveKey != null &&
        liveKey.isNotEmpty) {
      unawaited(
        ref
            .read(voiceRoomLiveProvider(liveKey).notifier)
            .leaveRoomSession(
              source: 'basic_dispose',
              awaitBackend: true,
              force: true,
            )
            .timeout(const Duration(seconds: 6))
            .catchError((_) {}),
      );
    }
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      unawaited(audio.leave());
    }
    super.dispose();
  }

  Future<UserEntity?> _waitForAuth() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future).timeout(
            VoiceRoomEntryPerf.entryBudget,
          );
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  void _startPremiumRealtime(UserEntity? user) {
    if (user == null) return;
    _startGiftRealtime();
    _maybeShowVipEntrance(user);
    unawaited(connectVoiceRoomBasicPkBattle(ref, _effectiveRoom()));
  }

  void _wireAudioReconnectCallbacks() {
    final audio = _audio;
    if (audio == null) return;
    audio.onReconnecting = () {
      if (!mounted || _leaving) return;
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.reconnecting,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses bağlantısı koptu — yeniden bağlanılıyor…'),
          duration: Duration(seconds: 2),
        ),
      );
    };
    audio.onReconnected = () {
      if (!mounted || _leaving) return;
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.connected,
          );
    };
  }

  Future<void> _joinAudioBackground() async {
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
      _startPremiumRealtime(user);
      return;
    }

    try {
      final roomId = room.apiRoomKey;
      if (!ref.read(voiceRoomLiveProvider(_liveRoomKey)).backendSyncReady) {
        final deadline = DateTime.now().add(const Duration(milliseconds: 1500));
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          if (ref.read(voiceRoomLiveProvider(_liveRoomKey)).backendSyncReady) {
            break;
          }
        }
      }
      final sync = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final staffBypass = StaffRoles.isSiteAdminUser(
        role: user.role,
        username: user.username,
      );
      _audio!.setStaffBypassVoiceApi(staffBypass);
      await _audio!.join(
        roomId: roomId,
        remote: ref.read(chatRoomRemoteProvider),
        enableMic: false,
        staffBypassVoiceApi: staffBypass,
        userId: user.id,
        backendTrtc: sync.roomTrtc,
      );
      if (!mounted) return;
      unawaited(VoiceRoomMusicAudioSession.activateForPlayback());
      _audio!.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
      _wireAudioReconnectCallbacks();
      setState(() {
        _audioJoining = false;
        _audioReady = true;
        _isMicMuted = !_audio!.micOn;
      });
      _startPremiumRealtime(user);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _audioJoining = false;
        _audioError = ApiException.userMessage(e);
      });
      _startPremiumRealtime(user);
    }
  }

  Future<void> _toggleMic() async {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    if (!muted) {
      final micOk = await VoiceTrtcEngine.requestMicrophonePermission();
      if (!micOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mikrofon izni gerekli. Ayarlardan mikrofonu açıp tekrar deneyin.',
            ),
          ),
        );
        return;
      }
      final user = ref.read(authControllerProvider).valueOrNull;
      final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final room = _effectiveRoom();
      ChatRoomPresence? selfPresence;
      for (final p in live.presence) {
        if (p.id == user?.id) {
          selfPresence = p;
          break;
        }
      }
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        selfPresence: selfPresence,
        server: live.serverPermissions,
      );
      if (!VoiceRoomSpeakAccess.canSpeak(
        user: user,
        perms: perms,
        room: room,
        presence: live.presence,
      )) {
        final notifier = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        final seated = await notifier.ensureSelfOnSeatForMic();
        if (!mounted) return;
        if (!seated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konuşmak için boş bir koltuğa oturmalısınız'),
            ),
          );
          return;
        }
        await notifier.refresh();
      }
    }
    try {
      await _audio!.setMicEnabled(!muted);
      if (mounted) setState(() => _isMicMuted = muted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _maybeAutoOpenMic() async {
    if (_audio == null || !_audioReady || !_isMicMuted) return;
    if (!ref.read(voiceRoomUiProvider).autoOpenMic) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
    final room = _effectiveRoom();
    ChatRoomPresence? selfPresence;
    for (final p in live.presence) {
      if (p.id == user?.id) {
        selfPresence = p;
        break;
      }
    }
    final perms = VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: selfPresence,
      server: live.serverPermissions,
      staffSiteAdmin: ref.read(staffAccessProvider).isSiteAdmin,
      walletRole: ref.read(staffAccessProvider).siteRole ??
          ref.read(walletBalancesProvider).valueOrNull?.role,
    );
    if (!VoiceRoomSpeakAccess.canSpeak(
      user: user,
      perms: perms,
      room: room,
      presence: live.presence,
    )) {
      return;
    }
    final micOk = await VoiceTrtcEngine.requestMicrophonePermission();
    if (!micOk || !mounted) return;
    try {
      await _audio!.setMicEnabled(true);
      if (mounted) setState(() => _isMicMuted = false);
    } catch (_) {}
  }

  void _onChatChanged(String text) {
    ref
        .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
        .notifyTyping(text.trim().isNotEmpty);
  }

  void _toggleSpeaker() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    final on = ref.read(voiceRoomUiProvider).headphonesOn;
    _audio?.setHeadphonesOn(on);
    unawaited(
      ref
          .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
          .applyAudioOutputGate(speakerOn: on),
    );
    if (mounted) setState(() {});
  }

  void _startGiftRealtime() {
    final room = _effectiveRoom();
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) return;
    ref.read(voiceRoomGiftRealtimeProvider).start(key);
  }

  void _maybeShowVipEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final cosmetic = ref.read(resolvedEntranceEffectProvider);
    final tier = ref.read(vipTierProvider);
    if (cosmetic == null && !tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    if (mounted) setState(() => _showVipEntrance = true);
  }

  void _openGiftShop(
    VoiceRoomEntity room,
    List<ChatRoomPresence> presence, {
    ChatRoomPresence? receiver,
  }) {
    openVoiceRoomBasicGiftShop(
      context,
      ref,
      room: room,
      presence: presence,
      receiver: receiver,
    );
  }

  void _sendChatMessage() {
    final text = VoiceOfficialJoin.normalizeCommandInput(
      _messageCtrl.text.trim(),
    );
    if (text.isEmpty) return;
    _messageCtrl.clear();
    unawaited(
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).sendMessage(text),
    );
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    _leaving = true;
    _leaveSessionStarted = true;
    final liveKey = _liveRoomKey;
    final room = _effectiveRoom();
    try {
      await VoiceRoomLeaveFlow.leaveWithSummary(
        context: context,
        ref: ref,
        liveKey: liveKey,
        room: room,
        source: 'basic_leave',
        prepareLeave: () async {
          ref.read(voiceRoomAudioCoordinatorProvider).setReconnectSuspended(true);
          _audio = null;
        },
      );
    } finally {
      if (mounted) _leaving = false;
    }
  }

  void _openMusicRequest(VoiceRoomEntity room) {
    unawaited(showVoiceYoutubeSongSheet(context, ref, room: room));
  }

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    final ok = await VoiceRoomLeaveFlow.confirmLeave(context);
    if (!ok || !mounted) return;
    await _leaveRoom();
  }

  void _openManagementPanel(
    VoiceRoomEntity room,
    VoiceRoomLiveState live,
    VoiceRoomPermissions perms,
    bool isOwner,
  ) {
    showVoiceRoomManagementPanel(
      context,
      ref,
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: (u) => _openUser(u, room, perms),
      onPkInvite: () => openVoiceRoomBasicPkInvite(context, ref, room),
    );
  }

  void _openUser(ChatRoomPresence user, VoiceRoomEntity room, VoiceRoomPermissions perms) {
    openVoiceRoomBasicUser(
      context,
      ref,
      room: room,
      liveKey: _liveRoomKey,
      user: user,
      perms: perms,
    );
  }

  /// Chat'te isme tek dokunuş → "@kullanıcı adı " mesaj kutusuna eklenir.
  void _insertMention(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    final existing = _messageCtrl.text;
    final needsSpace = existing.isNotEmpty && !existing.endsWith(' ');
    final mention = '@$n ';
    _messageCtrl.text = '$existing${needsSpace ? ' ' : ''}$mention';
    _messageCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageCtrl.text.length),
    );
  }

  /// Chat'te isme çift dokunuş → kullanıcı yetkileri (moderasyon) açılır.
  void _openUserById(
    String userId,
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
    VoiceRoomPermissions perms,
  ) {
    ChatRoomPresence? target;
    for (final p in live.presence) {
      if (p.id == userId) {
        target = p;
        break;
      }
    }
    if (target != null) _openUser(target, room, perms);
  }

  bool _canControlMusic(
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
    UserEntity? user,
    VoiceRoomPermissions perms,
  ) {
    final isDj = perms.canManageDj ||
        live.dj.canPlayMusic ||
        (user != null && room.djUserIds.contains(user.id)) ||
        live.dj.djUsers.any((u) => user != null && u.id == user.id);
    return live.dj.canControlMusic ||
        live.dj.canPlayMusic ||
        (user != null && live.dj.nowPlaying?.requestedBy?.id == user.id) ||
        perms.isRoomOwner ||
        perms.isSiteAdmin ||
        isDj;
  }

  VoiceRoomPermissions _permissions(
    UserEntity? user,
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
  ) {
    ChatRoomPresence? self;
    if (user != null) {
      for (final p in live.presence) {
        if (p.id == user.id) {
          self = p;
          break;
        }
      }
    }
    return VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: self,
      server: live.serverPermissions,
      staffSiteAdmin: ref.read(staffAccessProvider).isSiteAdmin,
      walletRole: ref.read(staffAccessProvider).siteRole ??
          ref.read(walletBalancesProvider).valueOrNull?.role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomKey = _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id;
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    ref.watch(
      voiceRoomLiveProvider(_liveRoomKey).select(_BasicLiveShell.fromState),
    );
    final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
    final roomErrorBanner =
        VoiceRoomErrorDisplay.bannerMessage(live.error, live: live);
    final ui = ref.watch(voiceRoomUiProvider);
    final room = _effectiveRoom();
    final online = live.onlineCountFor(room);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _permissions(user, live, room);
    final canControlMusic = _canControlMusic(live, room, user, perms);
    final canCloseMusic = VoiceMusicAccess.canStopMusic(
      user: user,
      perms: perms,
      nowPlaying: live.dj.nowPlaying,
    );
    final canSpeak = VoiceRoomSpeakAccess.canSpeak(
      user: user,
      perms: perms,
      room: room,
      presence: live.presence,
    );
    final speakPending = ui.requestSpeakPending;
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final showMusicRequestFab = live.dj.musicEnabled;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final sessionKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    String? hostAvatar;
    final ownerId = room.ownerId;
    if (ownerId != null) {
      for (final p in live.presence) {
        if (p.id == ownerId) {
          hostAvatar = p.image;
          break;
        }
      }
    }

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      if (!mounted) return;

      final exitMsg = VoiceRoomSessionExit.detectExitMessage(prev: prev, next: next);
      if (exitMsg != null && !_forcedExitHandled && !_leaving) {
        _forcedExitHandled = true;
        unawaited(
          VoiceRoomSessionExit.handleForcedExit(
            context: context,
            ref: ref,
            liveKey: _liveRoomKey,
            message: exitMsg,
          ),
        );
        return;
      }

      final toast = next.moderationToast;
      if (toast != null && toast != prev?.moderationToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toast), duration: const Duration(seconds: 4)),
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

      final q = next.pendingMusicSearchQuery;
      if (q != null &&
          prev?.pendingMusicSearchQuery != q &&
          mounted &&
          !_musicSearchOpen) {
        final skipPayment = next.pendingMusicSearchSkipPayment;
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        final dj = next.dj;
        ctrl.clearPendingMusicSearch();
        _musicSearchOpen = true;
        unawaited(
          showMusicSearchPickerSheet(
            context,
            ref,
            query: q,
            onSelected: (hit) async {
              if (!mounted) return;
              final withVideo = await showMusicModePickerSheet(
                context,
                audioCost: VoiceMusicAccess.audioRequestCost(dj),
                videoCost: VoiceMusicAccess.videoRequestCost(dj),
                songTitle: hit.title,
              );
              if (!mounted || withVideo == null) return;
              final messenger = ScaffoldMessenger.of(context);
              final songTitle = hit.title;
              deferVoiceMusicSubmit(
                submit: () => ctrl.submitSelectedSong(
                  hit,
                  withVideo: withVideo,
                  skipPayment: skipPayment,
                ),
                onComplete: (err) {
                  if (!mounted) return;
                  if (err != null) {
                    showJetonAwareError(context, err, ref: ref);
                  } else {
                    final liveNow =
                        ref.read(voiceRoomLiveProvider(_liveRoomKey));
                    final queuedOnly = liveNow.dj.playing &&
                        liveNow.dj.nowPlaying?.videoIdField != hit.videoId;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          queuedOnly
                              ? '«$songTitle» kuyruğa eklendi'
                              : '«$songTitle» çalmaya başladı',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ).whenComplete(() => _musicSearchOpen = false),
        );
      }

      if (next.error != null && next.error != prev?.error && mounted) {
        final err = next.error!;
        showJetonAwareError(context, err, ref: ref);
        ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).clearError();
      }

      if (next.openCommandsPanel && !(prev?.openCommandsPanel ?? false)) {
        ref
            .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
            .clearOpenCommandsPanel();
        if (!mounted) return;
        final room = _effectiveRoom();
        final userNow = ref.read(authControllerProvider).valueOrNull;
        final permsNow = _permissions(userNow, next, room);
        final owner = permsNow.isRoomOwner || permsNow.isSiteAdmin;
        unawaited(
          showVoiceRoomCommandsPanel(
            context,
            ref,
            room: room,
            perms: permsNow,
            isOwner: owner,
          ),
        );
      }

      if (_audioReady) {
        final user = ref.read(authControllerProvider).valueOrNull;
        if (user != null) {
          final room = _effectiveRoom();
          ChatRoomPresence? selfPresence;
          for (final p in next.presence) {
            if (p.id == user.id) {
              selfPresence = p;
              break;
            }
          }
          final perms = VoiceRoomPermissions.forUser(
            user: user,
            room: room,
            selfPresence: selfPresence,
            server: next.serverPermissions,
            staffSiteAdmin: ref.read(staffAccessProvider).isSiteAdmin,
            walletRole: ref.read(staffAccessProvider).siteRole ??
                ref.read(walletBalancesProvider).valueOrNull?.role,
          );
          final canSpeak = VoiceRoomSpeakAccess.canSpeak(
            user: user,
            perms: perms,
            room: room,
            presence: next.presence,
          );
          if (!canSpeak && !_isMicMuted) {
            _audio?.setMicEnabled(false);
            if (mounted) setState(() => _isMicMuted = true);
          } else if (canSpeak) {
            unawaited(_maybeAutoOpenMic());
          }
        }
      }
    });

    ref.listen(voiceRoomUiProvider, (prev, next) {
      if (prev?.autoOpenMic != next.autoOpenMic && next.autoOpenMic) {
        unawaited(_maybeAutoOpenMic());
      }
    });

    return GiftEventListener(
      sessionKey: sessionKey,
      isHost: isOwner,
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmLeave();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            VoiceCosmicBackground(imageUrl: bgUrl),
            if (_liveRoomKey.isNotEmpty) ...[
              VoiceRoomMusicBackgroundLayer(roomKey: _liveRoomKey),
              VoiceRoomHiddenAudioPlayer(roomKey: _liveRoomKey),
            ],
            Consumer(
              builder: (context, ref, _) {
                final activeGift = ref.watch(
                  giftSessionProvider(sessionKey)
                      .select((s) => s.activeAnimation),
                );
                final giftsOn = ref.watch(
                  voiceRoomUiProvider.select((s) => s.giftAnimationsEnabled),
                );
                return Positioned.fill(
                  child: IgnorePointer(
                    child: GiftEngineOverlay(
                      event: activeGift,
                      enabled: giftsOn,
                      stage: GiftStageContext.voiceRoom,
                      sessionKey: sessionKey,
                      onFinished: (id) {
                        ref
                            .read(giftSessionProvider(sessionKey).notifier)
                            .dequeueAnimation(id);
                      },
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              bottom: false,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VoiceLiveHeader2026(
                  room: room,
                  onlineCount: online,
                  coinBalance: jeton,
                  hostAvatarUrl: hostAvatar,
                  onBack: () => unawaited(_confirmLeave()),
                  onExit: () => unawaited(_confirmLeave()),
                  onAudience: () => showVoiceSpeakerListSheet(
                    context,
                    presence: live.presence,
                    room: room,
                    onUserTap: (u) => _openUser(u, room, perms),
                  ),
                  onCoinsTap: () => openJetonStore(context, ref: ref),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: VoiceOnlineGiftBox(
                      onlineCount: online,
                      onTap: () => showVoiceSpeakerListSheet(
                        context,
                        presence: live.presence,
                        room: room,
                        onUserTap: (u) => _openUser(u, room, perms),
                      ),
                    ),
                  ),
                ),
                if (live.roomMuted)
                  _Banner(message: 'Oda susturulmuş (yalnızca yetkililer konuşabilir)'),
                if (_loginError != null)
                  _Banner(message: _loginError!, isError: true),
                if (_audioError != null)
                  _Banner(message: _audioError!, isError: true),
                if (_audioJoining)
                  const LinearProgressIndicator(minHeight: 2),
                if (live.loading && live.presence.isEmpty)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else ...[
                  VoiceRoomBasicModerationSection(
                    room: room,
                    liveKey: _liveRoomKey,
                    live: live,
                    perms: perms,
                    user: user,
                    isMicMuted: _isMicMuted,
                  ),
                  VoiceRoomCenterMusicPanel(
                    room: room,
                    liveRoomKey: _liveRoomKey,
                    canControlMusic: canControlMusic,
                    canCloseMusic: canCloseMusic,
                  ),
                  // Aktif hediye savaşı — canlı skor + geri sayım.
                  GiftBattleStrip(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  // Aktif hediye hedefi — ilerleme çubuğu + kutlama.
                  GiftGoalBar(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  // Efsane İlk Destekçi rozeti (varsa).
                  FirstGifterBadge(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VoiceRoomBasicChatFeed(
                          liveKey: _liveRoomKey,
                          onMention: (userId, name) => _insertMention(name),
                          onUserPerms: (userId, name) =>
                              _openUserById(userId, live, room, perms),
                        ),
                      ],
                    ),
                  ),
                  if (roomErrorBanner != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        roomErrorBanner,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  VoiceRoomBasicMessageBar(
                    controller: _messageCtrl,
                    onSend: _sendChatMessage,
                    onChanged: _onChatChanged,
                    presence: live.presence,
                    selfUserId: user?.id,
                    onEmoji: () =>
                        showVoiceRoomBasicEmojiPicker(context, _messageCtrl),
                  ),
                  VoiceLiveActionBar2026(
                    micOn: !_isMicMuted,
                    micEnabled: _audioReady && !_audioJoining,
                    onMic: _toggleMic,
                    onGift: () => _openGiftShop(room, live.presence),
                    onSettings: () => _openManagementPanel(
                      room,
                      live,
                      perms,
                      isOwner,
                    ),
                    showSettings: false,
                    headphonesOn: ui.headphonesOn,
                    onToggleAudioOutput: _toggleSpeaker,
                    onInvite: () => unawaited(_shareRoom(room)),
                    showSpeakRequest: user != null && !canSpeak,
                    speakRequestPending: speakPending,
                    onSpeakRequest: () => unawaited(
                      requestVoiceRoomBasicSpeak(
                        context: context,
                        ref: ref,
                        liveKey: _liveRoomKey,
                        pending: speakPending,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ),
            VoiceGiftHudOverlays(sessionKey: sessionKey),
            if (_liveRoomKey.isNotEmpty)
              VoiceRoomVideoCloseBar(roomKey: _liveRoomKey),
            if (_liveRoomKey.isNotEmpty)
              BlocProvider.value(
                value: ref.read(roomSongBlocProvider(_liveRoomKey)),
                child: RoomSongMiniPlayer(
                  roomId: _liveRoomKey,
                  canControl: canControlMusic,
                  bottomInset: 88,
                  muted: ui.effectiveMusicMuted,
                  hidden: true,
                ),
              ),
            VoiceRoomSideActionRail(
              onSettings: () => _openManagementPanel(
                room,
                live,
                perms,
                isOwner,
              ),
              onMusic: showMusicRequestFab
                  ? () => _openMusicRequest(room)
                  : null,
              showMusic: showMusicRequestFab,
            ),
            if (!keyboardOpen && showMusicRequestFab)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 118, right: 4),
                  child: VoiceRoomMusicQueueMiniCard(
                    dj: live.dj,
                    liveKey: _liveRoomKey,
                    canControlMusic: canControlMusic,
                    canStopMusic: canCloseMusic,
                  ),
                ),
              ),
            if (_showVipEntrance && user != null)
              Builder(
                builder: (context) {
                  final name = user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!.trim()
                      : user.username;
                  final cosmetic = ref.watch(resolvedEntranceEffectProvider);
                  if (cosmetic != null) {
                    return CosmeticEntranceOverlay(
                      userName: name,
                      effectKind: cosmetic.effectKind,
                      onFinished: () {
                        if (mounted) setState(() => _showVipEntrance = false);
                      },
                    );
                  }
                  return VipEntranceOverlay(
                    tier: ref.watch(vipTierProvider),
                    theme: ref.watch(myEntranceThemeProvider),
                    userName: name,
                    onFinished: () {
                      if (mounted) setState(() => _showVipEntrance = false);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _shareRoom(VoiceRoomEntity room) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Canlifal sesli oda: ${room.displayTitle}\n'
            'https://canlifal.com/voice-room/${room.slug.isNotEmpty ? room.slug : room.id}',
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

/// Oda gövdesi rebuild sınırı — sohbet mesajları hariç.
class _BasicLiveShell {
  const _BasicLiveShell({
    required this.presence,
    required this.dj,
    required this.serverPermissions,
    required this.backgroundUrl,
    required this.loading,
    required this.error,
    required this.roomMuted,
    required this.realtimeEvents,
  });

  factory _BasicLiveShell.fromState(VoiceRoomLiveState s) => _BasicLiveShell(
        presence: s.presence,
        dj: s.dj,
        serverPermissions: s.serverPermissions,
        backgroundUrl: s.backgroundUrl,
        loading: s.loading,
        error: s.error,
        roomMuted: s.roomMuted,
        realtimeEvents: s.realtimeEvents,
      );

  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final ChatRoomMyPermissions? serverPermissions;
  final String? backgroundUrl;
  final bool loading;
  final String? error;
  final bool roomMuted;
  final List<VoiceRoomRealtimeEvent> realtimeEvents;

  @override
  bool operator ==(Object other) =>
      other is _BasicLiveShell &&
      identical(presence, other.presence) &&
      dj == other.dj &&
      serverPermissions == other.serverPermissions &&
      backgroundUrl == other.backgroundUrl &&
      loading == other.loading &&
      error == other.error &&
      roomMuted == other.roomMuted &&
      identical(realtimeEvents, other.realtimeEvents);

  @override
  int get hashCode => Object.hash(
        presence,
        dj,
        serverPermissions,
        backgroundUrl,
        loading,
        error,
        roomMuted,
        realtimeEvents,
      );
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
