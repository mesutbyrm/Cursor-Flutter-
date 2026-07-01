import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/live_entry_perf.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live_psychics/domain/entities/psychic_entity.dart';
import '../../../live_psychics/presentation/controllers/psychic_flow.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../../live_psychics/presentation/widgets/psychic_booking_sheet.dart';
import '../../../live_psychics/presentation/widgets/psychic_broadcast_side_rail.dart';
import '../../../live_psychics/presentation/widgets/psychic_fortune_types.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../gifts/presentation/widgets/premium_gift_panel.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../agora/presentation/agora_room_manager.dart';
import '../../../agora/presentation/providers/agora_providers.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_guest_layout.dart';
import '../../domain/utils/live_fortune_type_slug.dart';
import '../gifts/live_gift_controller.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../gifts/widgets/floating_gift_particles.dart';
import '../gifts/widgets/gift_notification_stack.dart';
import '../providers/live_providers.dart';
import '../../data/services/video_webrtc_signal_service.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_beauty_provider.dart';
import '../providers/live_guest_grid_provider.dart';
import '../providers/live_gift_leaderboard_provider.dart';
import '../providers/live_room_interaction_provider.dart'
    show LiveRoomInteractionNotifier, LiveRoomInteractionState, liveRoomInteractionProvider;
import '../providers/live_room_providers.dart';
import '../providers/live_video_pk_provider.dart';
import '../widgets/live_tiktok/live_background_picker_sheet.dart';
import '../widgets/live_tiktok/live_guest_grid.dart';
import '../widgets/broadcast_room/live_pk_score_bar.dart';
import '../providers/live_fortune_request_provider.dart';
import '../providers/live_stream_quality_provider.dart';
import '../widgets/broadcast_room/live_fortune_request_form.dart';
import '../widgets/broadcast_room/live_gift_leaderboard.dart';
import '../widgets/broadcast_room/live_like_realtime.dart';
import '../widgets/broadcast_room/live_moderation_sheet.dart';
import '../providers/live_broadcast_settings_provider.dart';
import '../widgets/broadcast_room/live_broadcast_settings_sheet.dart';
import '../widgets/broadcast_room/live_viewers_sheet.dart';
import '../widgets/broadcast_room/live_room_chat_fal_panel.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import '../widgets/broadcast_room/live_room_video_background.dart';
import '../widgets/live_playback_bridge.dart';
import '../widgets/premium_2026/live_premium_2026.dart';

/// Premium 2026 canlı yayın — TRTC + immersive overlay + hediye + kalpler.
class LiveBroadcastRoomPage extends ConsumerStatefulWidget {
  const LiveBroadcastRoomPage({
    super.key,
    required this.session,
    this.embeddedInSwipe = false,
    this.onSwipeClose,
  });

  final LiveBroadcastSession session;
  final bool embeddedInSwipe;
  final VoidCallback? onSwipeClose;

  @override
  ConsumerState<LiveBroadcastRoomPage> createState() =>
      _LiveBroadcastRoomPageState();
}

class _LiveBroadcastRoomPageState extends ConsumerState<LiveBroadcastRoomPage> {
  final _agora = AgoraRoomManager();
  var _rtcReady = false;
  String? _rtcError;
  final _chat = TextEditingController();

  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  final _heartsKey = GlobalKey<LiveFloatingHeartsOverlayState>();
  Key _localPreviewKey = UniqueKey();
  var _leaving = false;
  var _chatVisible = true;
  var _viewerAudioOn = true;
  VideoWebrtcSignalService? _signalService;
  Timer? _guestJoinPoll;
  Timer? _lazyGiftsTimer;
  Timer? _lazyExtrasTimer;
  final Set<String> _seenGuestJoinIds = {};
  final Set<String> _seenVipEntrances = {};
  String? _vipBannerName;
  VoidCallback? _remoteUidsListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final streamId = widget.session.streamId?.trim();
      if (streamId != null && streamId.isNotEmpty) {
        ref.read(liveRoomInteractionProvider(streamId).notifier)
          ..reset(initialLikes: 0)
          ..loadInitialLikeCount();
      }
      _initAgora();
      _lazyGiftsTimer = Timer(LazyLoadPerf.liveRoomGifts, () {
        if (mounted) _initGifts();
      });
      _lazyExtrasTimer = Timer(LazyLoadPerf.liveRoomExtras, () {
        if (mounted) _initStreamExtras();
      });
    });
  }

  void _initGifts() {
    final streamId = widget.session.streamId;
    if (streamId == null || streamId.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    ref.read(liveGiftControllerProvider).attach(
          streamId: streamId,
          receiverName: widget.session.streamerName ?? 'Yayıncı',
          initialCoins: user?.coinBalance,
        );
    unawaited(
      ref.read(liveGiftLeaderboardProvider(streamId).notifier).loadInitial(),
    );
  }

  bool _isBenignAgoraError(Object e) {
    final msg = e.toString();
    return msg.contains('-17') ||
        msg.contains('JOIN_CHANNEL_REJECTED') ||
        msg.contains('errJoinChannelRejected');
  }

  void _handleAgoraError(Object e) {
    debugPrint('[Agora] error: $e');
    if (_isBenignAgoraError(e)) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı hatası: yeniden deneniyor...')),
    );
  }

  void _onRtcJoinSuccess(UserEntity user) {
    if (!mounted) return;
    setState(() {
      _rtcReady = true;
      _rtcError = null;
      _localPreviewKey = UniqueKey();
    });
    ref.read(liveBeautyProvider.notifier).bindRtc(agora: _agora);
    final layout = _resolveGuestLayout();
    ref.read(liveGuestGridProvider.notifier)
      ..setLayout(layout)
      ..setHost(
        userId: user.id,
        name: widget.session.streamerName ?? user.display,
      );
    _remoteUidsListener ??= _onRemoteUidsChanged;
    _agora.remoteUidsNotifier.addListener(_remoteUidsListener!);
    _onRemoteUidsChanged();
    final quality = ref.read(liveStreamQualityProvider);
    unawaited(_agora.setStreamQuality(quality));
  }

  Future<void> _initAgora() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        setState(() => _rtcError = 'Yayın için giriş yapmalısınız');
      }
      return;
    }
    if (!_agora.isSupported) {
      if (mounted) {
        setState(
          () => _rtcError = 'Canlı yayın yalnızca Android/iOS cihazlarda desteklenir',
        );
      }
      return;
    }

    final roomId = widget.session.streamId?.trim() ?? '';
    try {
      if (roomId.isEmpty) {
        throw StateError('Yayın odası kimliği eksik');
      }

      var cred = widget.session.agora;
      if (cred == null || !cred.matchesChannel(roomId)) {
        cred = LiveEntryPerf.takeAgora(userId: user.id, streamId: roomId);
      }
      if (cred == null || !cred.matchesChannel(roomId)) {
        if (widget.session.isHost) {
          cred = await ref.read(agoraRemoteProvider).fetchToken(
                channelName: roomId,
                role: 'host',
              );
        } else {
          cred = await LiveEntryPerf.fetchAgoraParallel(
            ref,
            streamId: roomId,
            role: 'audience',
            userId: user.id,
          );
        }
      }

      await _agora.join(
        credentials: cred,
        isHost: widget.session.isHost,
      );
      if (widget.session.isHost) {
        await _agora.setCameraEnabled(widget.session.initialCameraOn);
        _agora.setMicEnabled(widget.session.initialMicOn);
        try {
          await ref.read(liveRemoteProvider).notifyLiveStarted(roomId);
        } catch (_) {}
      }
      _onRtcJoinSuccess(user);
    } catch (e) {
      if (_isBenignAgoraError(e) && _agora.inChannel) {
        debugPrint('[Agora] duplicate join ignored, channel active: $e');
        _onRtcJoinSuccess(user);
        return;
      }
      if (widget.session.isHost && roomId.isNotEmpty) {
        try {
          await ref.read(liveRepositoryProvider).endVideoStream(roomId);
        } catch (_) {}
        ref.invalidate(liveStreamsProvider);
      }
      if (mounted) {
        if (_isBenignAgoraError(e)) {
          _handleAgoraError(e);
          return;
        }
        _handleAgoraError(e);
        final msg = ApiException.userMessage(e);
        setState(() {
          _rtcError = msg.contains('Agora') ? 'Yayına bağlanılamadı' : msg;
        });
      }
    }
  }

  @override
  void dispose() {
    _lazyGiftsTimer?.cancel();
    _lazyExtrasTimer?.cancel();
    _guestJoinPoll?.cancel();
    _signalService?.stop();
    if (_remoteUidsListener != null) {
      _agora.remoteUidsNotifier.removeListener(_remoteUidsListener!);
    }
    _guestJoinPoll?.cancel();
    _chat.dispose();
    if (!_leaving &&
        widget.session.isHost &&
        widget.session.streamId?.isNotEmpty == true) {
      final streamId = widget.session.streamId!;
      unawaited(
        ref.read(liveRepositoryProvider).endVideoStream(streamId).catchError((_) {}),
      );
    }
    _agora.dispose();
    super.dispose();
  }

  bool _isFortuneBroadcast(LiveBroadcastSession s) {
    final cat = s.category.toLowerCase();
    if (cat.contains('fortune') || cat.contains('fal')) return true;
    return s.tags.any((t) {
      final l = t.toLowerCase();
      return l.contains('fal') ||
          l.contains('tarot') ||
          isLiveFortuneTypeKey(l);
    });
  }

  Future<bool> _submitStreamFortuneRequest({
    required String streamId,
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    int? jetonCost,
  }) async {
    try {
      final row =
          await ref.read(liveFortuneRequestsProvider(streamId).notifier).submit(
                displayName: displayName,
                question: question,
                fortuneType: fortuneType,
                priority: priority,
                jetonCost: jetonCost,
              );
      if (row != null) {
        ref.refreshWalletCache(force: true);
        return true;
      }
      final err = ref.read(liveFortuneRequestsProvider(streamId)).error;
      if (mounted && err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
      return false;
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fal isteği gönderilemedi. Lütfen tekrar deneyin.'),
          ),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _onFortuneRequest(LiveBroadcastSession s) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fal isteği için giriş yapın')),
      );
      return;
    }

    final streamId = s.streamId?.trim();
    if (streamId != null && streamId.isNotEmpty && _isFortuneBroadcast(s)) {
      final balance =
          ref.read(coinBalanceProvider) ?? user.coinBalance;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            left: 16,
            right: 16,
          ),
          child: LiveFortuneRequestForm(
            balance: balance,
            initialFortuneType: s.tags.isNotEmpty
                ? (isLiveFortuneTypeKey(s.tags.first)
                    ? s.tags.first
                    : liveFortuneCategoryToSlug(s.tags.first))
                : 'tarot',
            onSubmit: ({
              required displayName,
              required question,
              required fortuneType,
              required priority,
              required jetonCost,
            }) async {
              final success = await _submitStreamFortuneRequest(
                streamId: streamId,
                displayName: displayName,
                question: question,
                fortuneType: fortuneType,
                priority: priority,
                jetonCost: jetonCost,
              );
              if (success && ctx.mounted) Navigator.pop(ctx, true);
              return success;
            },
          ),
        ),
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fal isteğiniz kuyruğa eklendi')),
        );
      }
      return;
    }

    final hostId = s.hostUserId?.trim();
    PsychicEntity? psychic;
    if (hostId != null && hostId.isNotEmpty) {
      psychic = await ref.read(livePsychicsRepositoryProvider).fetchPsychic(hostId);
      if (psychic == null) {
        final list = await ref.read(livePsychicsRepositoryProvider).fetchPsychics();
        for (final p in list) {
          if (p.userId == hostId || p.id == hostId) {
            psychic = p;
            break;
          }
        }
      }
    }
    if (!mounted) return;
    if (psychic == null) {
      context.push('/canli-falcilar');
      return;
    }
    final options = PsychicDurationOption.forPsychic(psychic.pricePerMinute);
    final opt = options.length > 1 ? options[1] : options.first;
    final balance = ref.read(coinBalanceProvider) ?? user.coinBalance;
    if (balance < opt.totalJeton) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetersiz jeton. Gerekli: ${opt.totalJeton}')),
      );
      return;
    }
    final booking = await showPsychicBookingSheet(
      context,
      psychic: psychic,
      initialMinutes: opt.minutes,
    );
    if (!mounted || booking == null) return;
    await PsychicFlow.bookAndOpenWaiting(
      ref: ref,
      router: GoRouter.of(context),
      psychic: psychic,
      durationMinutes: booking.minutes,
      totalJeton: booking.jeton,
      fortuneType: booking.fortuneType,
    );
  }

  Future<void> _exitBroadcast(BuildContext context) async {
    if (_leaving) return;
    _leaving = true;
    ref.read(liveGiftControllerProvider).detach();
    await _agora.leave();
    final streamId = widget.session.streamId;
    if (widget.session.isHost && streamId != null && streamId.isNotEmpty) {
      try {
        await ref.read(liveRepositoryProvider).endVideoStream(streamId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Yayın sunucuda kapatılamadı: ${ApiException.userMessage(e)}',
              ),
            ),
          );
        }
      }
    }
    ref.invalidate(liveStreamsProvider);
    if (!context.mounted) return;
    if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
      widget.onSwipeClose!();
    } else {
      context.go('/feed');
    }
  }

  LiveRoomInteractionNotifier? _interactionNotifier() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return null;
    return ref.read(liveRoomInteractionProvider(streamId).notifier);
  }

  Future<void> _onFollow() async {
    final hostId = widget.session.hostUserId;
    final notifier = _interactionNotifier();
    if (hostId == null || hostId.isEmpty) {
      notifier?.setFollowing(true);
      return;
    }
    if (notifier == null) return;
    notifier.setFollowLoading(true);
    try {
      await ref.read(profileRepositoryProvider).follow(hostId);
      notifier.setFollowing(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      notifier.setFollowLoading(false);
    }
  }

  void _initStreamExtras() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    if (widget.session.isHost) {
      unawaited(ref.read(coBroadcastProvider.notifier).refresh());
      unawaited(ref.read(coBroadcastProvider.notifier).refreshStream(streamId));
      _guestJoinPoll?.cancel();
      _guestJoinPoll = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        unawaited(
          ref.read(coBroadcastProvider.notifier).refreshStream(streamId),
        );
      });
    }
    _signalService = ref.read(videoWebrtcSignalServiceProvider);
    _signalService?.onSignal = (sig) {
      if (!mounted) return;
      handleLiveLikeSignal(ref, streamId: streamId, signal: sig);
    };
    _signalService?.start(streamId: streamId);
  }

  Future<void> _onChatModeration(LiveRoomChatMessage message) async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null ||
        streamId.isEmpty ||
        !widget.session.isHost ||
        message.userId == null ||
        message.userId!.isEmpty) {
      return;
    }
    await showLiveModerationSheet(
      context: context,
      ref: ref,
      streamId: streamId,
      targetUserId: message.userId!,
      targetDisplayName: message.user,
      isModerator: message.isModerator,
    );
  }

  Future<void> _requestGuestJoin() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty || widget.session.isHost) return;
    final settings = ref.read(liveBroadcastSettingsProvider);
    if (!settings.guestsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayıncı konuk almayı kapattı')),
      );
      return;
    }
    try {
      await ref.read(coBroadcastProvider.notifier).requestJoin(streamId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayına katılma isteği gönderildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _promptGuestJoinRequest(Map<String, dynamic> request) async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty || !widget.session.isHost) return;
    final id = request['id']?.toString() ?? '';
    if (id.isEmpty || !_seenGuestJoinIds.add(id)) return;

    final name = request['userName']?.toString() ??
        request['displayName']?.toString() ??
        'İzleyici';
    final userId = request['userId']?.toString() ?? '';

    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Yayına katılma isteği'),
        content: Text('$name yayına katılmak istiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reddet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
    if (accept == null) return;
    try {
      if (accept && userId.isNotEmpty) {
        await ref.read(coBroadcastProvider.notifier).approveRequest(
              streamId: streamId,
              userId: userId,
            );
        ref.read(liveGuestGridProvider.notifier).addGuest(
              slotIndex: _nextEmptyGuestSlot(),
              userId: userId,
              displayName: name,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name yayına eklendi')),
          );
        }
      } else if (userId.isNotEmpty) {
        await ref.read(liveStreamExtrasProvider).coBroadcastAction(
              streamId: streamId,
              action: 'reject',
              userId: userId,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  void _onDoubleTapHeart() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    ref.read(liveRoomInteractionProvider(streamId).notifier).burstHearts(
          likes: 1,
        );
  }

  void _onTripleTapSuperLike() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    ref.read(liveRoomInteractionProvider(streamId).notifier).triggerSuperLike();
  }

  void _onLongPressApplause() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    final notifier = ref.read(liveRoomInteractionProvider(streamId).notifier);
    notifier.triggerApplause();
    notifier.triggerEmojiRain();
  }

  /// PK aktif/beklemede VEYA misafir modu → ekran üst/alt bölünür.
  bool _isSplitStage(LiveBroadcastSession s, String pkStatus) {
    final pkOn = pkStatus == 'active' || pkStatus == 'pending';
    final guestOn = _resolveGuestLayout() != LiveGuestLayout.solo;
    return pkOn || guestOn;
  }

  LiveGuestLayout _resolveGuestLayout() {
    final settings = ref.read(liveBroadcastSettingsProvider);
    if (settings.guestLayout != LiveGuestLayout.solo) {
      return settings.guestLayout;
    }
    return widget.session.guestLayout;
  }

  int _nextEmptyGuestSlot() {
    final slots = ref.read(liveGuestGridProvider).slots;
    for (var i = 1; i < slots.length; i++) {
      if (slots[i].isEmpty) return i;
    }
    return slots.length > 1 ? 1 : 1;
  }

  void _onRemoteUidsChanged() {
    ref
        .read(liveGuestGridProvider.notifier)
        .syncRemoteUids(_agora.remoteUidsNotifier.value);
  }

  void _onGuestAction(int slotIndex, String action) {
    final grid = ref.read(liveGuestGridProvider.notifier);
    switch (action) {
      case 'pin':
        grid.togglePin(slotIndex);
      case 'mute':
        grid.toggleGuestMute(slotIndex);
        final slots = ref.read(liveGuestGridProvider).slots;
        if (slotIndex < slots.length) {
          final uid = slots[slotIndex].agoraUid;
          if (uid != null) {
            unawaited(_agora.muteRemoteAudio(uid, slots[slotIndex].mutedByHost));
          }
        }
      case 'cam':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konuk kamera kontrolü yakında')),
        );
    }
  }

  Future<void> _openControlCenter() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    await openLiveHostControlCenter(
      context: context,
      ref: ref,
      streamId: streamId,
      isHost: widget.session.isHost,
    );
  }

  Map<String, dynamic>? _pkBattleExtras(Map<String, dynamic>? battle) {
    if (battle == null) return null;
    final seconds = battle['secondsLeft'] ?? battle['remainingSeconds'];
    final top = battle['topSupporter'] ?? battle['top_supporter'];
    final mvp = battle['mvp'] ?? battle['mvpName'];
    final winner = battle['winner'] ?? battle['winnerSide'];
    final parsedSeconds = switch (seconds) {
      final int v => v,
      final num v => v.round(),
      final v => int.tryParse('$v'),
    };
    return {
      'secondsLeft': parsedSeconds,
      'topSupporter': top?.toString(),
      'mvpName': mvp?.toString(),
      'winnerSide': winner?.toString(),
    };
  }

  int? _pkOverlayInt(Map<String, dynamic>? extras, String key) {
    final v = extras?[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse('$v');
  }

  Future<void> _openPkPanel() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PK daveti bu sürümde kullanılamıyor.')),
    );
  }

  Future<void> _openHostTools() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151522),
      showDragHandle: true,
      builder: (ctx) {
        Future<void> run(Future<void> Function() action, String ok) async {
          try {
            await action();
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Yayın Araçları',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('Web canlı yayın özellikleriyle uyumlu hızlı işlemler'),
                ),
                ListTile(
                  leading: const Icon(Icons.image_rounded),
                  title: const Text('Resim modunu kapak görseliyle güncelle'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).setBroadcastImage(
                          streamId: streamId,
                          imageUrl: widget.session.coverImageUrl ??
                              widget.session.avatarUrl ??
                              'https://canlifal.com/apple-touch-icon.png',
                        ),
                    'Yayın görseli güncellendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper_rounded),
                  title: const Text('Arka plan değiştir'),
                  onTap: () {
                    Navigator.pop(ctx);
                    LiveBackgroundPickerSheet.show(
                      context,
                      selectedUrl: widget.session.backgroundUrl,
                      onSelectUrl: (url) => run(
                        () => ref.read(liveStreamExtrasProvider).setBackground(
                              streamId: streamId,
                              backgroundUrl: url ??
                                  'https://canlifal.com/apple-touch-icon.png',
                            ),
                        'Yayın arka planı güncellendi.',
                      ),
                      onSelectFile: (_) {},
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper_outlined),
                  title: const Text('Canlifal varsayılan arka plan'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).setBackground(
                          streamId: streamId,
                          backgroundUrl: widget.session.backgroundUrl ??
                              'https://canlifal.com/apple-touch-icon.png',
                        ),
                    'Yayın arka planı güncellendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.group_add_rounded),
                  title: const Text('Co-broadcast davetlerini yenile'),
                  onTap: () => run(
                    () async {
                      await ref.read(coBroadcastProvider.notifier).refresh();
                    },
                    'Ortak yayın davetleri yenilendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_off_rounded),
                  title: const Text('Auto-close kontrolü çalıştır'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).triggerAutoClose(streamId),
                    'Auto-close kontrolü tetiklendi.',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareLive() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    final url = 'https://canlifal.com/sohbet/video/broadcast/$streamId';
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.session.title}\n$url',
        subject: 'Canlifal canlı yayını',
      ),
    );
  }

  String _fmtLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _videoLayer(LiveBroadcastSession s) {
    if (s.backgroundUrl?.trim().isNotEmpty == true && !s.isImageMode) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CanlifalNetworkImage(
            url: s.backgroundUrl!,
            fit: BoxFit.cover,
            errorWidget: const SizedBox.shrink(),
          ),
          _mainVideo(s),
        ],
      );
    }
    if (s.isImageMode && s.coverImageUrl?.trim().isNotEmpty == true) {
      return _imageModeLayer(s);
    }
    return _mainVideo(s);
  }

  Widget _mainVideo(LiveBroadcastSession s) {
    if (!_rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (!s.isHost)
            LivePlaybackBridge(
              playbackUrl: s.playbackUrl,
              thumbnailUrl: s.coverImageUrl ?? s.avatarUrl,
            )
          else
            _imageModeLayer(s),
          if (_rtcError == null && s.isHost)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sensors_rounded,
                    size: 56,
                    color: Color(0xFFB832FF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yayın başlatılıyor…',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          if (_rtcError == null && !s.isHost)
            Positioned(
              left: 16,
              bottom: 128,
              child: _liveConnectingBadge(),
            ),
          if (_rtcError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _rtcError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      );
    }

    final remoteUid = _agora.remoteUidNotifier.value;
    final layout = _resolveGuestLayout();
    return ValueListenableBuilder<List<int>>(
      valueListenable: _agora.remoteUidsNotifier,
      builder: (context, remoteUids, _) {
        return LiveGuestGrid(
          layout: layout,
          isHost: s.isHost,
          agora: _agora,
          localPreviewKey: _localPreviewKey,
          hostAvatarUrl: s.avatarUrl,
          hostName: s.streamerName,
          remoteUid: remoteUid,
          onInviteSlot: s.isHost ? (_) => _openControlCenter() : null,
          onGuestAction: s.isHost ? _onGuestAction : null,
        );
      },
    );
  }

  Widget _liveConnectingBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Canlı bağlanıyor',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageModeLayer(LiveBroadcastSession s) {
    final image = s.coverImageUrl?.trim();
    final bg = s.backgroundUrl?.trim();
    final url = image?.isNotEmpty == true ? image : bg;
    if (url == null || url.isEmpty) return const LiveRoomVideoBackground();
    return Stack(
      fit: StackFit.expand,
      children: [
        CanlifalNetworkImage(
          url: url,
          fit: BoxFit.cover,
          errorWidget: const LiveRoomVideoBackground(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openHostProfile(BuildContext context, LiveBroadcastSession s) {
    final handle = s.streamerHandle?.trim();
    if (handle != null && handle.isNotEmpty) {
      context.push('/user/${Uri.encodeComponent(handle)}');
      return;
    }
    final id = s.hostUserId;
    if (id != null && id.isNotEmpty) {
      context.push('/user/$id');
    }
  }

  Widget _viewerSideRail({
    required LiveBroadcastSession s,
    required LiveRoomInteractionState interaction,
    required LiveGiftController giftCtrl,
    String? streamId,
  }) {
    if (!s.isHost) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (streamId != null && streamId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LiveLikeButton(streamId: streamId),
            ),
          PsychicBroadcastSideRail(
            viewerCount: s.viewerCount,
            onGift: () => giftCtrl.setPanelOpen(true),
            onFortuneRequest: () => unawaited(_onFortuneRequest(s)),
            showFortuneRequest: _isFortuneBroadcast(s),
            onViewersTap: streamId != null && streamId.isNotEmpty
                ? () => showLiveViewersSheet(
                      context,
                      ref,
                      streamId: streamId,
                      isHost: s.isHost,
                    )
                : null,
            onNickname: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rumuz ayarları yakında')),
              );
            },
            onToggleAudio: () => setState(() => _viewerAudioOn = !_viewerAudioOn),
            onExit: () => unawaited(_confirmEnd(context)),
            audioOn: _viewerAudioOn,
          ),
        ],
      );
    }
    return LivePremiumSideRail(
      likeLabel: _fmtLikes(interaction.likeCount),
      giftLabel: giftCtrl.streamerEarnings != null
          ? '${giftCtrl.streamerEarnings}'
          : 'Hediye',
      shareLabel: 'Paylaş',
      onLike: _onDoubleTapHeart,
      onGift: () => giftCtrl.setPanelOpen(true),
      onShare: _shareLive,
      onReport: s.streamId != null && s.streamId!.isNotEmpty
          ? () => openReportFlow(
                context,
                ReportTarget(
                  type: ReportTargetType.liveStream,
                  targetId: s.streamId!,
                  displayTitle: s.streamerName ?? 'Canlı yayın',
                ),
              )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseSession = widget.session;
    final streamId = baseSession.streamId?.trim();
    final hasStream = streamId != null && streamId.isNotEmpty;
    final roomState =
        hasStream ? ref.watch(liveRoomProvider(streamId)) : const LiveRoomState();
    final s = baseSession.copyWith(viewerCount: roomState.viewerCount);
    final top = MediaQuery.paddingOf(context).top;
    final giftCtrl = ref.watch(liveGiftControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final interaction = hasStream
        ? ref.watch(liveRoomInteractionProvider(streamId))
        : const LiveRoomInteractionState();
    final pkState = hasStream ? ref.watch(liveVideoPkProvider(streamId)) : null;
    final fortuneReqState = hasStream && s.isHost
        ? ref.watch(liveFortuneRequestsProvider(streamId))
        : null;
    final balance = ref.watch(coinBalanceProvider) ?? user?.coinBalance;
    final broadcastSettings = ref.watch(liveBroadcastSettingsProvider);

    if (hasStream && s.isHost) {
      ref.listen(coBroadcastProvider, (prev, next) {
        ref
            .read(liveGuestGridProvider.notifier)
            .syncCoBroadcasters(next.coBroadcasters);
        for (final req in next.joinRequests) {
          if ((req['status']?.toString() ?? 'pending') == 'pending') {
            unawaited(_promptGuestJoinRequest(req));
          }
        }
      });
    }

    if (hasStream) {
      ref.listen(liveRoomProvider(streamId), (prev, next) {
        if (next.fortuneAnsweredNotice != null &&
            next.fortuneAnsweredNotice != prev?.fortuneAnsweredNotice) {
          final notice = next.fortuneAnsweredNotice!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(notice)),
            );
            ref
                .read(liveRoomProvider(streamId).notifier)
                .clearFortuneAnsweredNotice();
          });
        }
        if (next.streamEnded && !(prev?.streamEnded ?? false) && !s.isHost) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Yayın sona erdi'),
              content: const Text('Yayıncı yayını kapattı.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
            widget.onSwipeClose!();
          } else {
            context.go('/live');
          }
        });
        }
      });
    }

    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      if (hasStream) {
        final prevIds =
            prev?.notifications.map((e) => e.id).toSet() ?? const <String>{};
        for (final ev in next.notifications) {
          if (!prevIds.contains(ev.id)) {
            ref.read(liveGiftLeaderboardProvider(streamId).notifier).record(ev);
          }
        }
      }
      final queue = next.fullscreenQueue;
      final prevQueue = prev?.fullscreenQueue ?? const [];
      if (queue.isNotEmpty && queue.first != (prevQueue.isNotEmpty ? prevQueue.first : null)) {
        final ev = queue.first;
        final emoji = LiveGiftCatalog.emojiById[ev.giftId] ?? '💖';
        _particlesKey.currentState?.burst(
          emoji,
          count: 6 + ev.combo.clamp(0, 12).toInt(),
        );
        if (hasStream) {
          ref
              .read(liveRoomInteractionProvider(streamId).notifier)
              .pulseHeartsVisual();
          final battle = ref.read(liveVideoPkProvider(streamId)).battle;
          if (battle != null && battle['status'] == 'active') {
            unawaited(ref.read(liveVideoPkProvider(streamId).notifier).refresh());
          }
        }
      }
    });

    if (hasStream) {
      ref.listen(liveRoomProvider(streamId), (prev, next) {
        if (next.messages.length > (prev?.messages.length ?? 0)) {
          for (final m in next.messages.skip(prev?.messages.length ?? 0)) {
            if (m.isVip && !m.isSystem) {
              final key = m.userId ?? m.user;
              if (_seenVipEntrances.add(key)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _vipBannerName = m.user);
                });
              }
            }
          }
        }
      });
    }

    final pkExtras = _pkBattleExtras(pkState?.battle);
    final pkStatus = pkState?.status ?? '';

    return PopScope(
      canPop: widget.embeddedInSwipe,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmEnd(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // PK veya misafir modunda ekran üst/alt bölünür: üst yarı video/PK
            // alanı, alt yarı hediye + chat. Normal yayında tam ekran video.
            if (_isSplitStage(s, pkStatus))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: _videoLayer(s),
              )
            else
              Positioned.fill(child: _videoLayer(s)),
            if (_isSplitStage(s, pkStatus))
              Positioned(
                top: MediaQuery.sizeOf(context).height * 0.5,
                left: 0,
                right: 0,
                bottom: 0,
                child: const ColoredBox(color: Colors.black),
              ),
            const LiveImmersiveScrim(),
            LiveFloatingHeartsOverlay(
              key: _heartsKey,
              burstToken: interaction.heartBurstToken,
              onDoubleTap: _onDoubleTapHeart,
              onTripleTap: _onTripleTapSuperLike,
              onLongPress: _onLongPressApplause,
            ),
            LiveInteractionEffectsOverlay(
              burstToken: interaction.heartBurstToken,
              superLikeToken: interaction.superLikeToken,
              emojiRainToken: interaction.emojiRainToken,
              applauseToken: interaction.applauseToken,
            ),
            FloatingGiftParticles(key: _particlesKey),
            Positioned.fill(
              child: IgnorePointer(
                child: LiveGiftAnimationStack(
                  events: List.from(giftCtrl.fullscreenQueue),
                ),
              ),
            ),
            if (hasStream && pkState?.battle != null &&
                (pkStatus == 'active' || pkStatus == 'ended'))
              LivePkPremiumOverlay(
                leftScore: pkState!.leftScore,
                rightScore: pkState.rightScore,
                status: pkStatus,
                secondsLeft: _pkOverlayInt(pkExtras, 'secondsLeft'),
                topSupporter: pkExtras?['topSupporter']?.toString(),
                mvpName: pkExtras?['mvpName']?.toString(),
                winnerSide: pkExtras?['winnerSide']?.toString(),
              ),
            if (_vipBannerName != null)
              Positioned(
                top: top + 72,
                left: 16,
                right: 16,
                child: LiveVipEntranceBanner(
                  displayName: _vipBannerName!,
                  onDone: () => setState(() => _vipBannerName = null),
                ),
              ),
            if (hasStream)
              Positioned(
                left: 12,
                bottom: 200,
                child: LiveGiftLeaderboard(streamId: streamId),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, top > 0 ? 4 : 12, 12, 0),
                    child: LivePremiumTopBar(
                      session: s,
                      elapsedBadge: const LiveElapsedTimePill(),
                      following: interaction.following,
                      followLoading: interaction.followLoading,
                      onFollow: _onFollow,
                      onClose: () => _confirmEnd(context),
                      onViewersTap: hasStream
                          ? () => showLiveViewersSheet(
                                context,
                                ref,
                                streamId: streamId,
                                isHost: s.isHost,
                              )
                          : null,
                      onProfileTap: s.hostUserId != null || s.streamerHandle != null
                          ? () => _openHostProfile(context, s)
                          : null,
                      onBack: widget.embeddedInSwipe
                          ? () => unawaited(_confirmEnd(context))
                          : null,
                    ),
                  ),
                  if (hasStream && pkState?.battle != null && pkStatus == 'pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Builder(
                        builder: (_) {
                          // Davetin rakip tarafı kabul/red edebilir. Canlı yayın
                          // PK'sında rakip de kendi yayınının host'udur; bu yüzden
                          // !isHost yerine isOpponent kullanılır.
                          final canRespond = pkState!.isOpponent;
                          return LivePkScoreBar(
                            leftScore: pkState.leftScore,
                            rightScore: pkState.rightScore,
                            status: pkStatus,
                            isHost: s.isHost,
                            onAccept: canRespond
                                ? () => ref
                                    .read(liveVideoPkProvider(streamId).notifier)
                                    .accept()
                                : null,
                            onReject: canRespond
                                ? () => ref
                                    .read(liveVideoPkProvider(streamId).notifier)
                                    .reject()
                                : null,
                          );
                        },
                      ),
                    )
                  else if (s.isHost)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: broadcastSettings.pkEnabled ? _openPkPanel : null,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.sports_mma_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'PK Başlat',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: hasStream
                                  ? _openControlCenter
                                  : null,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFFFD700),
                                size: 16,
                              ),
                              label: Text(
                                'Kontrol (${fortuneReqState?.pendingCount ?? 0})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => showLiveBroadcastSettingsSheet(
                                context: context,
                                ref: ref,
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Ayarlar',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => showLiveBeautyFilterSheet(
                                context: context,
                                ref: ref,
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.face_retouching_natural_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Güzellik',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _openHostTools,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Araçlar',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_chatVisible)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _chatVisible = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white, size: 18),
                                Text(
                                  'Sohbeti gizle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_chatVisible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GiftNotificationStack(
                                  events: giftCtrl.notifications,
                                ),
                                const SizedBox(height: 8),
                                LiveRoomChatFalPanel(
                                  messages: roomState.messages.isEmpty
                                      ? const [
                                          LiveRoomChatMessage(
                                            user: 'Sistem',
                                            text: 'Canlı yayına hoş geldin',
                                            isSystem: true,
                                          ),
                                        ]
                                      : roomState.messages,
                                  showFortuneTab:
                                      !s.isHost && _isFortuneBroadcast(s),
                                  canModerate: s.isHost,
                                  onMessageLongPress: s.isHost
                                      ? (m) => unawaited(_onChatModeration(m))
                                      : null,
                                  balance: balance,
                                  initialFortuneType: s.tags.isNotEmpty
                                      ? (isLiveFortuneTypeKey(s.tags.first)
                                          ? s.tags.first
                                          : liveFortuneCategoryToSlug(
                                              s.tags.first,
                                            ))
                                      : null,
                                  onSubmitFortuneRequest: hasStream
                                      ? ({
                                          required displayName,
                                          required question,
                                          required fortuneType,
                                          required priority,
                                          required jetonCost,
                                        }) =>
                                            _submitStreamFortuneRequest(
                                              streamId: streamId,
                                              displayName: displayName,
                                              question: question,
                                              fortuneType: fortuneType,
                                              priority: priority,
                                              jetonCost: jetonCost,
                                            )
                                      : ({
                                          required displayName,
                                          required question,
                                          required fortuneType,
                                          required priority,
                                          required jetonCost,
                                        }) async =>
                                            false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _viewerSideRail(
                            s: s,
                            interaction: interaction,
                            giftCtrl: giftCtrl,
                            streamId: streamId,
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _chatVisible = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sohbet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _viewerSideRail(
                            s: s,
                            interaction: interaction,
                            giftCtrl: giftCtrl,
                            streamId: streamId,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  LivePremiumBottomBar(
                    chatController: _chat,
                    isHost: s.isHost,
                    agora: s.isHost ? _agora : null,
                    commentsEnabled: broadcastSettings.commentsEnabled,
                    onJoinBroadcast: !s.isHost &&
                            broadcastSettings.guestsEnabled &&
                            hasStream
                        ? () => unawaited(_requestGuestJoin())
                        : null,
                    onRtcStateChanged: s.isHost
                        ? () => setState(() => _localPreviewKey = UniqueKey())
                        : null,
                    onToggleCamera: s.isHost
                        ? () {
                            _agora.setCameraEnabled(!_agora.cameraOn);
                            setState(() => _localPreviewKey = UniqueKey());
                          }
                        : null,
                    onGift: broadcastSettings.giftsEnabled
                        ? () => giftCtrl.setPanelOpen(true)
                        : null,
                    onSend: () {
                      final t = _chat.text.trim();
                      if (t.isEmpty || streamId == null || streamId.isEmpty) {
                        return;
                      }
                      _chat.clear();
                      unawaited(
                        ref.read(liveRoomProvider(streamId).notifier).sendMessage(
                              t,
                              selfName: user?.display ?? 'Sen',
                            ),
                      );
                    },
                    onEnd: s.isHost ? () => _confirmEnd(context) : null,
                  ),
                ],
              ),
            ),
            if (giftCtrl.panelOpen && user != null && broadcastSettings.giftsEnabled)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PremiumGiftPanel(
                  controller: giftCtrl,
                  streamId: widget.session.streamId ?? '',
                  senderName: user.display,
                  senderId: user.id,
                  onClose: () => giftCtrl.setPanelOpen(false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Yayını bitir?'),
        content: const Text('Canlı yayından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _exitBroadcast(context);
  }
}
