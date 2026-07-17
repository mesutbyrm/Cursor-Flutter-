import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../live_psychics/presentation/widgets/psychic_fortune_types.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../gifts/domain/session_gift_summary_builder.dart';
import '../../../gifts/presentation/widgets/session_gift_summary_sheet.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../gifts/presentation/widgets/gift_goal_bar.dart';
import '../../../gifts/presentation/widgets/premium_gift_panel.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../data/host_live_stream_recovery.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_guest_layout.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../../domain/live_guest_layout_resolver.dart';
import '../providers/live_namespace_providers.dart';
import '../../domain/utils/live_fortune_type_slug.dart';
import '../gifts/live_gift_controller.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../gifts/providers/live_seat_gift_flash_provider.dart';
import '../gifts/widgets/floating_gift_particles.dart';
import '../gifts/widgets/gift_notification_stack.dart';
import '../providers/pk_room_providers.dart';
import '../providers/live_pk_invite_signal_provider.dart';
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
import '../widgets/pk/pk_room_live_section.dart';
import '../providers/live_fortune_request_provider.dart';
import '../providers/live_stream_quality_provider.dart';
import '../widgets/broadcast_room/live_fortune_request_form.dart';
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
    this.active = true,
  });

  final LiveBroadcastSession session;
  final bool embeddedInSwipe;
  final VoidCallback? onSwipeClose;

  /// Kaydırmalı izleyicide yalnızca ekrandaki sayfa `true`. Ekranda olmayan
  /// (ısıtılmış komşu) sayfalar sesi kısar ki yayınlar üst üste duyulmasın.
  final bool active;

  @override
  ConsumerState<LiveBroadcastRoomPage> createState() =>
      _LiveBroadcastRoomPageState();
}

class _LiveBroadcastRoomPageState extends ConsumerState<LiveBroadcastRoomPage>
    with WidgetsBindingObserver {
  final _trtc = TrtcRoomManager();
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
  Timer? _fortunePoll;
  Timer? _lazyGiftsTimer;
  Timer? _lazyExtrasTimer;
  Timer? _coBroadcastPoll;
  Timer? _hostHeartbeat;
  final Set<String> _seenGuestJoinIds = {};
  final Set<String> _seenCoBroadcastInviteIds = {};
  final Set<String> _seenPkInviteIds = {};
  final Set<String> _seenVipEntrances = {};
  var _coHostUpgraded = false;
  String? _vipBannerName;
  VoidCallback? _remoteUidsListener;
  VoidCallback? _remoteVideoListener;
  var _hostAway = false;
  DateTime? _graceEndsAt;
  var _hostAwayViewerNotified = false;
  var _hadHostVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final streamId = widget.session.streamId?.trim();
      if (streamId != null && streamId.isNotEmpty) {
        final hostId = widget.session.hostUserId?.trim();
        if (hostId != null && hostId.isNotEmpty) {
          ref.read(liveFortuneHostUserIdProvider(streamId).notifier).state =
              hostId;
        }
        ref.read(liveRoomInteractionProvider(streamId).notifier)
          ..reset(initialLikes: 0)
          ..loadInitialLikeCount();
      }
      _initTrtc();
      _lazyGiftsTimer = Timer(LazyLoadPerf.liveRoomGifts, () {
        if (mounted) _initGifts();
      });
      _lazyExtrasTimer = Timer(LazyLoadPerf.liveRoomExtras, () {
        if (mounted) _initStreamExtras();
      });
    });
  }

  @override
  void didUpdateWidget(covariant LiveBroadcastRoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _applyActiveAudio();
    }
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

  bool _isBenignRtcError(Object e) {
    final msg = e.toString();
    return msg.contains('-17') ||
        msg.contains('JOIN_CHANNEL_REJECTED') ||
        msg.contains('errJoinChannelRejected');
  }

  void _handleRtcError(Object e) {
    debugPrint('[TRTC] error: $e');
    if (_isBenignRtcError(e)) return;
    if (!mounted) return;
    if (widget.session.isHost && !_leaving) {
      unawaited(_enterHostGracePeriod(notifyViewers: true));
      return;
    }
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
    ref.read(liveBeautyProvider.notifier).bindRtc(trtc: _trtc);
    final layout = _resolveGuestLayout();
    ref.read(liveGuestGridProvider.notifier)
      ..setLayout(layout)
      ..setHost(
        userId: user.id,
        name: widget.session.streamerName ?? user.display,
      );
    _remoteUidsListener ??= _onRemoteUidsChanged;
    _trtc.remoteUserIdsNotifier.addListener(_remoteUidsListener!);
    _onRemoteUidsChanged();
    if (!widget.session.isHost) {
      _remoteVideoListener ??= _onHostVideoAvailabilityChanged;
      _trtc.remoteVideoAvailable.addListener(_remoteVideoListener!);
      _onHostVideoAvailabilityChanged();
    } else {
      _startHostHeartbeat();
    }
    final quality = ref.read(liveStreamQualityProvider);
    unawaited(_trtc.setStreamQuality(quality));
    _applyActiveAudio();
  }

  /// Ekranda olmayan (ısıtılmış) yayının sesini kıs; ekrandakini aç. Yayıncı
  /// kendi sesini duymaz zaten; bu yalnızca uzak sese uygulanır.
  void _applyActiveAudio() {
    if (!widget.embeddedInSwipe) return;
    _trtc.muteAllRemoteAudioStreams(!widget.active);
  }

  Future<void> _initTrtc() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        setState(() => _rtcError = 'Yayın için giriş yapmalısınız');
      }
      return;
    }
    if (!_trtc.isSupported) {
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

      var cred = widget.session.trtc;
      if (cred == null || !cred.matchesRoom(roomId)) {
        cred = LiveEntryPerf.takeTrtc(userId: user.id, streamId: roomId);
      }
      if (cred == null || !cred.matchesRoom(roomId)) {
        if (widget.session.isHost) {
          cred = await ref.read(trtcRemoteProvider).fetchToken(
                roomId: roomId,
                role: 'host',
                userId: user.id,
              );
        } else {
          cred = await LiveEntryPerf.fetchTrtcParallel(
            ref: ref,
            streamId: roomId,
            role: 'audience',
            userId: user.id,
          );
        }
      }

      final resolvedCred = cred;
      if (resolvedCred == null || !resolvedCred.matchesRoom(roomId)) {
        throw StateError('TRTC oturumu alınamadı');
      }

      await _trtc.join(
        credentials: resolvedCred,
        isHost: widget.session.isHost,
        audioOnly: false,
      );
      if (widget.session.isHost) {
        _trtc.setCameraEnabled(widget.session.initialCameraOn);
        _trtc.setMicEnabled(widget.session.initialMicOn);
        try {
          await ref.read(liveRemoteProvider).notifyLiveStarted(roomId);
        } catch (_) {}
      }
      _onRtcJoinSuccess(user);
    } catch (e) {
      if (_isBenignRtcError(e) && _trtc.inChannel) {
        debugPrint('[TRTC] duplicate join ignored, channel active: $e');
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
        if (_isBenignRtcError(e)) {
          _handleRtcError(e);
          return;
        }
        _handleRtcError(e);
        final msg = ApiException.userMessage(e);
        setState(() {
          _rtcError = msg.contains('TRTC') || msg.contains('token')
              ? 'Yayına bağlanılamadı'
              : msg;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lazyGiftsTimer?.cancel();
    _lazyExtrasTimer?.cancel();
    _guestJoinPoll?.cancel();
    _fortunePoll?.cancel();
    _coBroadcastPoll?.cancel();
    _hostHeartbeat?.cancel();
    _signalService?.stop();
    if (_remoteUidsListener != null) {
      _trtc.remoteUserIdsNotifier.removeListener(_remoteUidsListener!);
    }
    if (_remoteVideoListener != null) {
      _trtc.remoteVideoAvailable.removeListener(_remoteVideoListener!);
    }
    _chat.dispose();
    if (!_leaving) {
      if (widget.session.isHost &&
          widget.session.streamId?.isNotEmpty == true) {
        unawaited(HostLiveStreamRecovery.save(widget.session));
      } else if (_trtc.inChannel) {
        unawaited(_trtc.leave());
      }
    }
    _trtc.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.session.isHost || _leaving) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_enterHostGracePeriod(notifyViewers: false));
    } else if (state == AppLifecycleState.resumed && _hostAway) {
      unawaited(_resumeHostBroadcast());
    }
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
    final streamId = widget.session.streamId?.trim() ?? '';
    final user = ref.read(authControllerProvider).valueOrNull;

    if (widget.session.isHost && streamId.isNotEmpty) {
      unawaited(_trtc.leave());
      unawaited(
        ref.read(liveRemoteProvider).sendStreamMessage(
              streamId: streamId,
              content: 'Yayıncı yayını kapattı.',
            ),
      );
      unawaited(
        ref.read(liveRepositoryProvider).endVideoStream(streamId).then(
          (_) => HostLiveStreamRecovery.clear(),
          onError: (_) => HostLiveStreamRecovery.clear(),
        ),
      );
      ref.read(liveRoomProvider(streamId).notifier).markStreamEnded();
    } else {
      try {
        await _trtc.leave();
      } catch (_) {}
    }

    if (streamId.isNotEmpty && user != null) {
      final hostId = widget.session.hostUserId?.trim().isNotEmpty == true
          ? widget.session.hostUserId!.trim()
          : (widget.session.isHost ? user.id : '');
      final summary = SessionGiftSummaryBuilder.forLiveBroadcast(
        ref: ref,
        streamId: streamId,
        hostUserId: hostId.isNotEmpty ? hostId : user.id,
        hostDisplayName: widget.session.streamerName ?? user.display,
        myUserId: user.id,
      );
      await SessionGiftSummaryBuilder.refreshWalletIfRecipient(ref, summary);
      if (context.mounted) {
        await showSessionGiftSummarySheet(context, summary: summary);
      }
    } else {
      await ref.refreshWalletCache(force: true);
    }

    ref.invalidate(liveStreamsProvider);
    if (!context.mounted) return;
    if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
      widget.onSwipeClose!();
    } else {
      context.go('/feed');
    }
  }

  Future<void> _showViewerStreamEndedSummary(String streamId) async {
    if (_leaving || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || streamId.isEmpty) return;
    final hostId = widget.session.hostUserId?.trim() ?? '';
    final summary = SessionGiftSummaryBuilder.forLiveBroadcast(
      ref: ref,
      streamId: streamId,
      hostUserId: hostId.isNotEmpty ? hostId : user.id,
      hostDisplayName: widget.session.streamerName ?? 'Yayıncı',
      myUserId: user.id,
    );
    await SessionGiftSummaryBuilder.refreshWalletIfRecipient(ref, summary);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Yayıncı yayını kapattı'),
        content: Text(
          summary.hasData
              ? 'Yayın sona erdi. Hediye özetiniz bir sonraki ekranda.'
              : 'Bu yayın sona erdi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (summary.hasData) {
      await showSessionGiftSummarySheet(context, summary: summary);
    }
    if (!mounted) return;
    if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
      widget.onSwipeClose!();
    } else {
      context.go('/live');
    }
  }

  Future<void> _enterHostGracePeriod({required bool notifyViewers}) async {
    if (!widget.session.isHost || _leaving || _hostAway) return;
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    _hostAway = true;
    _graceEndsAt = DateTime.now().add(HostLiveStreamRecovery.gracePeriod);
    await HostLiveStreamRecovery.save(widget.session);
    if (_trtc.inChannel) {
      await _trtc.leave();
    }
    if (notifyViewers) {
      try {
        await ref.read(liveRemoteProvider).sendStreamMessage(
              streamId: streamId,
              content:
                  'Yayıncının internet bağlantısı koptu. Yayın 5 dakika daha açık kalacak.',
            );
      } catch (_) {}
    }
    if (mounted) setState(() => _rtcReady = false);
  }

  void _startHostHeartbeat() {
    _hostHeartbeat?.cancel();
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    _hostHeartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_leaving || !widget.session.isHost) return;
      unawaited(ref.read(liveRemoteProvider).sendStreamHeartbeat(streamId));
      if (!_trtc.inChannel && _hostAway) {
        unawaited(_resumeHostBroadcast(silent: true));
      }
    });
  }

  Future<void> _resumeHostBroadcast({bool silent = false}) async {
    if (!widget.session.isHost || _leaving) return;
    final endsAt = _graceEndsAt;
    if (endsAt != null && DateTime.now().isAfter(endsAt)) {
      _hostAway = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeniden bağlanma süresi doldu.')),
        );
      }
      return;
    }
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    try {
      if (_trtc.inChannel) {
        _hostAway = false;
        await HostLiveStreamRecovery.clear();
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yayına kaldığınız yerden devam ediliyor.')),
          );
        }
        return;
      }
      final meta = await ref.read(liveRemoteProvider).fetchStream(streamId);
      if (meta != null && !meta.isLive && endsAt == null) {
        await HostLiveStreamRecovery.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yayın sona ermiş.')),
          );
        }
        return;
      }
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) return;
      final cred = await ref.read(trtcRemoteProvider).fetchToken(
            roomId: streamId,
            role: 'host',
            userId: user.id,
          );
      await _trtc.join(credentials: cred, isHost: true, audioOnly: false);
      _trtc.setCameraEnabled(widget.session.initialCameraOn);
      _trtc.setMicEnabled(widget.session.initialMicOn);
      try {
        await ref.read(liveRemoteProvider).notifyLiveStarted(streamId);
      } catch (_) {}
      _hostAway = false;
      _onRtcJoinSuccess(user);
      await HostLiveStreamRecovery.clear();
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yayına kaldığınız yerden devam ediliyor.')),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  void _onHostVideoAvailabilityChanged() {
    if (widget.session.isHost || _leaving) return;
    final available = _trtc.remoteVideoAvailable.value;
    if (available) {
      _hadHostVideo = true;
      return;
    }
    if (!_hadHostVideo || _hostAwayViewerNotified) return;
    _hostAwayViewerNotified = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Yayıncının internet bağlantısı koptu. Yayın 5 dakika daha açık kalacak.',
        ),
        duration: Duration(seconds: 8),
      ),
    );
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
      final layout = widget.session.guestLayout;
      if (layout != LiveGuestLayout.solo) {
        final settings = ref.read(liveBroadcastSettingsProvider.notifier);
        settings.toggleCoBroadcast(true);
        settings.toggleGuests(true);
        settings.setGuestLayout(layout);
        ref.read(liveGuestGridProvider.notifier).setLayout(layout);
      }
      unawaited(ref.read(coBroadcastProvider.notifier).refresh());
      unawaited(ref.read(coBroadcastProvider.notifier).refreshStream(streamId));
      unawaited(_applyGuestPresenceFromApi(streamId));
      _guestJoinPoll?.cancel();
      _guestJoinPoll = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) return;
        unawaited(
          ref.read(coBroadcastProvider.notifier).refreshStream(streamId),
        );
        // İzleyici: bekleyen ortak yayın davetlerini de yenile.
        if (!widget.session.isHost) {
          unawaited(ref.read(coBroadcastProvider.notifier).refresh());
        }
      });
      unawaited(ref.read(liveFortuneRequestsProvider(streamId).notifier).refresh());
      _fortunePoll?.cancel();
      _fortunePoll = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        unawaited(
          ref.read(liveFortuneRequestsProvider(streamId).notifier).refresh(),
        );
      });
    } else {
      _coBroadcastPoll?.cancel();
      _coBroadcastPoll = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) return;
        unawaited(_syncCoBroadcastGuest(streamId));
      });
      unawaited(_syncCoBroadcastGuest(streamId));
      unawaited(_applyGuestPresenceFromApi(streamId));
    }

    _signalService = ref.read(videoWebrtcSignalServiceProvider);
    _signalService?.onSignal = (sig) {
      if (!mounted) return;
      handleLiveLikeSignal(ref, streamId: streamId, signal: sig);
      _handlePkSignal(streamId, sig);
    };
    _signalService?.start(streamId: streamId);
    if (widget.session.isHost) {
      unawaited(_bootstrapPkInvites(streamId));
    }
  }

  /// PK skor sinyali — anlık senkron (poll'u beklemeden).
  void _handlePkSignal(String streamId, Map<String, dynamic> sig) {
    final type = (sig['type'] ?? sig['event'] ?? '').toString().toLowerCase();
    if (type != 'pk' && type != 'pkbattle' && type != 'pk_battle') return;
    final payload = sig['payload'] is Map
        ? Map<String, dynamic>.from(sig['payload'] as Map)
        : sig;
    final battle = payload['battle'] ?? payload['pk'];
    if (battle is Map) {
      ref
          .read(liveVideoPkProvider(streamId).notifier)
          .applyRemoteBattle(Map<String, dynamic>.from(battle));
    } else {
      // Payload battle taşımıyorsa provider'ı tazele.
      ref.read(liveVideoPkProvider(streamId).notifier).refresh();
    }
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
    if (!settings.guestsEnabled && !settings.coBroadcastEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yayıncı konuk almayı kapattı — yine de istek gönderiliyor…',
          ),
        ),
      );
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
        _enableMultiGuestLayout(
          LiveGuestLayout.duo,
          [
            {'userId': userId, 'displayName': name},
          ],
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

  Future<void> _promptCoBroadcastInvite(
    String streamId,
    Map<String, dynamic> invite,
  ) async {
    if (widget.session.isHost) return;
    final id = (invite['id'] ??
            invite['inviteId'] ??
            invite['streamId'] ??
            streamId)
        .toString();
    if (id.isEmpty || !_seenCoBroadcastInviteIds.add(id)) return;
    final hostName = (invite['hostName'] ??
            invite['streamerName'] ??
            invite['fromName'] ??
            'Yayıncı')
        .toString();
    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Ortak yayın daveti',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$hostName sizi ortak yayına davet etti.',
          style: const TextStyle(color: Colors.white70),
        ),
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
    if (!mounted || accept == null) return;
    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (accept) {
        await ref.read(coBroadcastProvider.notifier).acceptInvite(streamId);
        if (user != null) {
          await _upgradeToCoHost(streamId, user);
        }
      } else {
        await ref.read(coBroadcastProvider.notifier).rejectInvite(streamId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  Future<void> _syncCoBroadcastGuest(String streamId) async {
    if (widget.session.isHost || _coHostUpgraded || _leaving) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
      final approved = ref.read(coBroadcastProvider).coBroadcasters.any((c) {
        final uid = c['userId']?.toString() ?? c['id']?.toString();
        final status = (c['status'] ?? c['state'] ?? 'approved').toString();
        return uid == user.id &&
            (status == 'approved' ||
                status == 'active' ||
                status == 'joined');
      });
      if (approved) {
        await _upgradeToCoHost(streamId, user);
      }
    } catch (_) {}
  }

  Future<void> _upgradeToCoHost(String streamId, UserEntity user) async {
    if (_coHostUpgraded || widget.session.isHost || !_rtcReady) return;
    try {
      final cred = await ref.read(trtcRemoteProvider).fetchToken(
            roomId: streamId,
            role: 'host',
            userId: user.id,
          );
      await _trtc.leave();
      await _trtc.join(credentials: cred, isHost: true, audioOnly: false);
      _trtc.setCameraEnabled(true);
      _trtc.setMicEnabled(true);
      _coHostUpgraded = true;
      _enableMultiGuestLayout(
        LiveGuestLayout.duo,
        [
          {
            'userId': user.id,
            'displayName': user.display,
            'userName': user.display,
          },
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Misafir yayınına geçildi — kamera açık')),
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

  void _enableMultiGuestLayout(
    LiveGuestLayout layout,
    List<Map<String, dynamic>> guests,
  ) {
    final settings = ref.read(liveBroadcastSettingsProvider.notifier);
    settings.toggleCoBroadcast(true);
    settings.toggleGuests(true);
    settings.setGuestLayout(layout);
    ref.read(liveGuestGridProvider.notifier)
      ..setLayout(layout)
      ..syncCoBroadcasters(guests);
    if (mounted) setState(() {});
  }

  Future<void> _applyGuestPresenceFromApi(String streamId) async {
    try {
      final snap =
          await ref.read(liveApiRemoteProvider).fetchGuestList(streamId: streamId);
      if (snap.count <= 0 && snap.guests.isEmpty) return;
      final guests = snap.toCoBroadcasters();
      final layout = resolveGuestLayout(
        guestCount: snap.count > 0 ? snap.count : guests.length,
        gridSlots: snap.gridSlots,
      );
      _enableMultiGuestLayout(layout, guests);
    } catch (_) {}
  }

  Future<void> _bootstrapPkInvites(String streamId) async {
    if (_leaving) return;
    try {
      ref.invalidate(pkPendingInvitesProvider);
      await ref.read(liveVideoPkProvider(streamId).notifier).refresh();
      if (mounted) _applyPkInvites(streamId);
    } catch (_) {}
  }

  void _applyPkInvites(String streamId) {
    if (_leaving || !mounted) return;
    final battle = ref.read(liveVideoPkProvider(streamId)).battle;
    if (battle != null) {
      _maybeShowPkInvite(streamId, battle);
    }
    final invites = ref.read(pkPendingInvitesProvider).valueOrNull ?? const [];
    for (final inv in invites) {
      if (!inv.isPending) continue;
      if (inv.hostStreamId == streamId) continue;
      final map = pkRoomMatchToBattleMap(inv, myStreamId: streamId);
      _maybeShowPkInvite(streamId, map);
    }
  }

  void _maybeShowPkInvite(String streamId, Map<String, dynamic> battle) {
    if (!widget.session.isHost) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final status = battle['status']?.toString() ?? '';
    if (status != 'pending') return;
    if (!isLivePkInviteRecipientMap(
      battle,
      myStreamId: streamId,
      myUserId: userId,
    )) {
      return;
    }
    final id = battle['id']?.toString() ?? '';
    if (id.isEmpty || !_seenPkInviteIds.add(id)) return;
    final hostStream = battle['hostStreamId']?.toString();
    if (hostStream != null && hostStream.isNotEmpty && hostStream == streamId) {
      return;
    }
    unawaited(_showIncomingLivePkInvite(streamId, id, battle));
  }

  Future<void> _showIncomingLivePkInvite(
    String streamId,
    String battleId,
    Map<String, dynamic> battle,
  ) async {
    if (!mounted) return;
    final challenger = battle['leftName']?.toString() ??
        battle['challengerName']?.toString() ??
        'Yayıncı';
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
        content: Text(
          '$challenger size PK daveti gönderdi.\nKabul ediyor musunuz?',
          style: const TextStyle(color: Colors.white70),
        ),
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
    if (!mounted || accept == null) return;
    try {
      if (battle['unifiedPk'] == true) {
        await ref.read(pkUnifiedInviteProvider).respond(
              matchId: battleId,
              accept: accept,
            );
      } else {
        final pk = ref.read(liveVideoPkProvider(streamId).notifier);
        if (accept) {
          await pk.accept();
        } else {
          await pk.reject();
        }
      }
      if (accept && mounted) {
        await ref.read(liveVideoPkProvider(streamId).notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PK başlatılıyor…')),
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
  bool _isSplitStage(LiveBroadcastSession s, String pkStatus,
      {bool hasCoGuests = false}) {
    final pkOn = pkStatus == 'active' || pkStatus == 'pending';
    final guestOn =
        _resolveGuestLayout() != LiveGuestLayout.solo || hasCoGuests;
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
        .syncRemoteUserIds(_trtc.remoteUserIdsNotifier.value);
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
          final userId = slots[slotIndex].rtcUserId ?? slots[slotIndex].userId;
          if (userId != null && userId.isNotEmpty) {
            _trtc.muteRemoteAudio(userId, slots[slotIndex].mutedByHost);
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
    await context.push('/live/pk-invite', extra: widget.session);
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

  Future<void> _openGamesHub() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oyunlar yakında canlı yayında açılacak')),
    );
  }

  Future<void> _openLiveMoreMenu({
    required LiveBroadcastSession s,
    required bool giftsEnabled,
    required bool pkEnabled,
    required int pendingFortune,
  }) async {
    final streamId = s.streamId?.trim();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151522),
      showDragHandle: true,
      builder: (ctx) {
        Widget tile({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return ListTile(
            leading: Icon(icon, color: Colors.white70),
            title: Text(label),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.isHost) ...[
                if (pkEnabled)
                  tile(
                    icon: Icons.sports_mma_rounded,
                    label: 'PK Başlat',
                    onTap: () => unawaited(_openPkPanel()),
                  ),
                tile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Kontrol merkezi ($pendingFortune)',
                  onTap: () => unawaited(_openControlCenter()),
                ),
                tile(
                  icon: Icons.settings_rounded,
                  label: 'Yayın ayarları',
                  onTap: () => showLiveBroadcastSettingsSheet(
                    context: context,
                    ref: ref,
                  ),
                ),
                tile(
                  icon: Icons.face_retouching_natural_rounded,
                  label: 'Güzellik filtresi',
                  onTap: () => showLiveBeautyFilterSheet(
                    context: context,
                    ref: ref,
                  ),
                ),
                tile(
                  icon: Icons.tune_rounded,
                  label: 'Yayın araçları',
                  onTap: () => unawaited(_openHostTools()),
                ),
              ] else ...[
                tile(
                  icon: Icons.volume_up_rounded,
                  label: _viewerAudioOn ? 'Sesi kapat' : 'Sesi aç',
                  onTap: () => setState(() => _viewerAudioOn = !_viewerAudioOn),
                ),
                if (streamId != null && streamId.isNotEmpty)
                  tile(
                    icon: Icons.flag_outlined,
                    label: 'Bildir',
                    onTap: () => openReportFlow(
                      context,
                      ReportTarget(
                        type: ReportTargetType.liveStream,
                        targetId: streamId,
                        displayTitle: s.streamerName ?? 'Canlı yayın',
                      ),
                    ),
                  ),
              ],
              tile(
                icon: Icons.share_rounded,
                label: 'Paylaş',
                onTap: () => unawaited(_shareLive()),
              ),
              if (giftsEnabled)
                tile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hediye kutusu',
                  onTap: () =>
                      ref.read(liveGiftControllerProvider).setPanelOpen(true),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _fmtLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _viewerSideRail({
    required LiveBroadcastSession s,
    required LiveRoomInteractionState interaction,
    required LiveGiftController giftCtrl,
  }) {
    return LiveMockupSideRail(
      likeLabel: _fmtLikes(interaction.likeCount),
      onLike: _onDoubleTapHeart,
      showFortune: !s.isHost && _isFortuneBroadcast(s),
      onFortune: !s.isHost && _isFortuneBroadcast(s)
          ? () => unawaited(_onFortuneRequest(s))
          : null,
      onGiftPackages: () => giftCtrl.setPanelOpen(true),
    );
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

    final remoteUid = _trtc.remoteAnchorUserIdNotifier.value;
    final layout = _resolveGuestLayout();
    final hostJeton = ref.read(liveGiftControllerProvider).streamerEarnings ?? 0;
    return ValueListenableBuilder<List<String>>(
      valueListenable: _trtc.remoteUserIdsNotifier,
      builder: (context, remoteUids, _) {
        return LiveGuestGrid(
          layout: layout,
          isHost: s.isHost,
          trtc: _trtc,
          localPreviewKey: _localPreviewKey,
          hostAvatarUrl: s.avatarUrl,
          hostName: s.streamerName,
          remoteUserId: remoteUid,
          hostJetonEarned: hostJeton,
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
    final coBroadcast = ref.watch(coBroadcastProvider);
    final hasCoGuests = coBroadcast.coBroadcasters.isNotEmpty;

    if (hasStream && s.isHost) {
      ref.listen(coBroadcastProvider, (prev, next) {
        if (next.coBroadcasters.isNotEmpty) {
          final layout = resolveGuestLayout(
            guestCount: next.coBroadcasters.length,
          );
          if (_resolveGuestLayout() == LiveGuestLayout.solo) {
            _enableMultiGuestLayout(layout, next.coBroadcasters);
          } else {
            ref
                .read(liveGuestGridProvider.notifier)
                .syncCoBroadcasters(next.coBroadcasters);
          }
        }
        for (final req in next.joinRequests) {
          if ((req['status']?.toString() ?? 'pending') == 'pending') {
            unawaited(_promptGuestJoinRequest(req));
          }
        }
      });
      ref.listen(liveFortuneRequestsProvider(streamId), (prev, next) {
        final pulse = next.newRequestPulse;
        if (pulse <= (prev?.newRequestPulse ?? 0)) return;
        final pending = next.requests
            .where(
              (r) =>
                  r.status == LiveFortuneRequestStatus.pending ||
                  r.status == LiveFortuneRequestStatus.held,
            )
            .toList();
        if (pending.isEmpty) return;
        final latest = pending.last;
        final queueNo = pending.indexWhere((r) => r.id == latest.id) + 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fal bildirimi #$queueNo: ${latest.displayName} — ${latest.fortuneType}',
              ),
              action: SnackBarAction(
                label: 'Gör',
                onPressed: _openControlCenter,
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        });
      });
      ref.listen(liveVideoPkProvider(streamId), (prev, next) {
        final battle = next.battle;
        if (battle != null) {
          _maybeShowPkInvite(streamId, battle);
        }
      });
      ref.listen(pkPendingInvitesProvider, (_, next) {
        next.whenData((invites) {
          for (final inv in invites) {
            if (!inv.isPending) continue;
            if (inv.hostStreamId == streamId) continue;
            _maybeShowPkInvite(
              streamId,
              pkRoomMatchToBattleMap(inv, myStreamId: streamId),
            );
          }
        });
      });
      ref.listen(livePkInviteSignalProvider, (_, __) {
        _applyPkInvites(streamId);
      });
    }

    // Misafir ortak yayın daveti (co-broadcast invite) — izleyici tarafı.
    if (hasStream && !s.isHost) {
      ref.listen(coBroadcastProvider, (prev, next) {
        for (final inv in next.invites) {
          final status = (inv['status']?.toString() ?? 'pending').toLowerCase();
          if (status != 'pending') continue;
          final invStream = (inv['streamId'] ??
                  inv['videoStreamId'] ??
                  inv['liveStreamId'] ??
                  '')
              .toString();
          if (invStream.isNotEmpty && invStream != streamId) continue;
          unawaited(_promptCoBroadcastInvite(streamId, inv));
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
            if (!mounted || _leaving) return;
            _leaving = true;
            try {
              await _trtc.leave();
            } catch (_) {}
            await _showViewerStreamEndedSummary(streamId);
          });
        }
      });
    }

    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      if (hasStream) {
        final earnings = next.streamerEarnings ?? 0;
        ref.read(liveGuestGridProvider.notifier).setHostJeton(earnings);
        final prevIds =
            prev?.notifications.map((e) => e.id).toSet() ?? const <String>{};
        for (final ev in next.notifications) {
          if (!prevIds.contains(ev.id)) {
            ref.read(liveGiftLeaderboardProvider(streamId).notifier).record(ev);
            if (ev.jetonAmount >= 1000) {
              ref.read(staffEntranceMarqueeProvider.notifier).enqueueBigGift(
                    senderName: ev.senderName,
                    receiverName: ev.receiverName,
                    jeton: ev.jetonAmount,
                    giftName: ev.giftName,
                  );
            }
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
          count: 6 + (ev.quantity * ev.coinCost ~/ 100).clamp(0, 12),
        );
        if (hasStream) {
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
        await _exitBroadcast(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // PK veya misafir modunda ekran üst/alt bölünür: üst yarı video/PK
            // alanı, alt yarı hediye + chat. Normal yayında tam ekran video.
            if (_isSplitStage(s, pkStatus, hasCoGuests: hasCoGuests))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: _videoLayer(s),
              )
            else
              Positioned.fill(child: _videoLayer(s)),
            if (_isSplitStage(s, pkStatus, hasCoGuests: hasCoGuests))
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
            // Tek hediye katmanı: chat üstü bildirim + (premium ise) fullscreen.
            // Center toast kaldırıldı — çift/üst üste binen gösterim olmasın.
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
                top: top + 108,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.42,
                  child: GiftGoalBar(
                    context: 'live_stream',
                    contextId: streamId,
                  ),
                ),
              ),
            if (hasStream)
              Positioned(
                right: 12,
                top: top + 108,
                child: LiveStarTournamentCard(
                  rank: 3,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yıldız Turnuvası yakında'),
                      ),
                    );
                  },
                ),
              ),
            if (hasStream)
              Positioned(
                left: 12,
                bottom: 210,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.55,
                  child: PkRoomLiveSection(
                    streamId: streamId,
                    myUserId: user?.id ?? '',
                  ),
                ),
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
                      onClose: () => unawaited(_exitBroadcast(context)),
                      topGifters: hasStream
                          ? ref.watch(liveGiftLeaderboardProvider(streamId))
                          : const [],
                      popularRank: s.isHost || s.viewerCount > 0 ? 1 : null,
                      leagueLabel: 'Lig 1',
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
                      onDiscoverTap: () => context.go('/live'),
                      onBack: widget.embeddedInSwipe
                          ? () => unawaited(_exitBroadcast(context))
                          : null,
                    ),
                  ),
                  if (hasStream && pkState?.battle != null && pkStatus == 'pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Builder(
                        builder: (_) {
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
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: LivePremiumBottomBar(
                      chatController: _chat,
                      isHost: s.isHost,
                      trtc: s.isHost ? _trtc : null,
                      commentsEnabled: broadcastSettings.commentsEnabled,
                      chatVisible: _chatVisible,
                      onToggleChat: () =>
                          setState(() => _chatVisible = !_chatVisible),
                      onGuest: !s.isHost &&
                              broadcastSettings.guestsEnabled &&
                              hasStream
                          ? () => unawaited(_requestGuestJoin())
                          : s.isHost && hasStream
                              ? () => unawaited(_openControlCenter())
                              : null,
                      onCoBroadcast: s.isHost && hasStream
                          ? () => unawaited(_openPkPanel())
                          : broadcastSettings.guestsEnabled && hasStream
                              ? () => unawaited(_requestGuestJoin())
                              : null,
                      onGames: () => unawaited(_openGamesHub()),
                      onShare: () => unawaited(_shareLive()),
                      onMore: () => unawaited(
                        _openLiveMoreMenu(
                          s: s,
                          giftsEnabled: broadcastSettings.giftsEnabled,
                          pkEnabled: broadcastSettings.pkEnabled,
                          pendingFortune: fortuneReqState?.pendingCount ?? 0,
                        ),
                      ),
                      onRtcStateChanged: s.isHost
                          ? () => setState(() => _localPreviewKey = UniqueKey())
                          : null,
                      onToggleCamera: s.isHost
                          ? () {
                              _trtc.setCameraEnabled(!_trtc.cameraOn);
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
                          ref
                              .read(liveRoomProvider(streamId).notifier)
                              .sendMessage(
                                t,
                                selfName: user?.display ?? 'Sen',
                              ),
                        );
                      },
                      onEnd:
                          s.isHost ? () => unawaited(_exitBroadcast(context)) : null,
                    ),
                  ),
                ],
              ),
            ),
            if (_hostAway && s.isHost)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Bağlantı koptu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yayın 5 dakika daha açık. Geri döndüğünüzde devam edebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => unawaited(_resumeHostBroadcast()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yayına devam et'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => unawaited(_exitBroadcast(context)),
                            child: const Text('Yayını bitir'),
                          ),
                        ],
                      ),
                    ),
                  ),
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
}
