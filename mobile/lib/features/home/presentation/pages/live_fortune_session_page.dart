import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/widgets/broadcast_room/live_room_video_background.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../widgets/live_fortune_extend_sheet.dart';
import '../widgets/live_fortune_tip_sheet.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../live_fortune/live_fortune_close_dialog.dart';
import '../providers/home_providers.dart';
import '../providers/live_fortune_room_sse_provider.dart';

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
  final _chatScroll = ScrollController();
  final _messages = <TellerChatMessage>[];
  final _seenChatIds = <String>{};
  var _rtcReady = false;
  String? _rtcError;
  var _leaving = false;
  var _sendingChat = false;
  var _waitingForTimer = false;
  var _timerStarted = false;
  int? _tipThankYouAmount;
  LiveFortuneRoomInfo? _room;
  String? _lastChatAfter;
  late Duration _remaining;
  Timer? _tick;
  Timer? _chatPoll;
  Timer? _ping;
  Timer? _roomPoll;
  var _sseConnected = false;
  Key _localPreviewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: widget.session.durationMinutes);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapRoom();
      if (!mounted) return;
      await _joinRtc();
      await _connectRoomSse();
      _startChatPoll();
    });
  }

  Future<void> _bootstrapRoom() async {
    await _syncRoomInfo(startTimerIfTeller: true);
    _startTimers();
  }

  void _startTimers() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _leaving) return;
      if (!_timerStarted) return;
      final secs = _room?.remainingSeconds ?? _remaining.inSeconds - 1;
      if (secs <= 0) {
        unawaited(_onTimeUp());
        return;
      }
      setState(() => _remaining = Duration(seconds: secs));
    });

    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 60), (_) => _sendPing());

    _roomPoll?.cancel();
    _roomPoll = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_syncRoomInfo());
    });
  }

  Future<void> _syncRoomInfo({bool startTimerIfTeller = false}) async {
    if (!mounted || _leaving) return;
    final remote = ref.read(homeRemoteProvider);
    final previousRoomId = _room?.roomId;
    final info = await remote.fetchRoomInfo(widget.session.sessionId);
    if (!mounted || info == null) return;

    final wasTimerStarted = _timerStarted;
    final maxMinutes = info.maxMinutes > 0
        ? info.maxMinutes
        : widget.session.durationMinutes;

    if (startTimerIfTeller &&
        !widget.session.isClient &&
        !info.timerStarted) {
      final result = await remote.roomAction(
        widget.session.sessionId,
        'start_timer',
      );
      if (result != null) {
        final startedAtRaw = result['timerStartedAt']?.toString();
        final startedAt = startedAtRaw != null
            ? DateTime.tryParse(startedAtRaw)
            : DateTime.now();
        _room = info.copyWith(
          timerStarted: true,
          timerStartedAt: startedAt,
          maxMinutes: maxMinutes,
        );
        _timerStarted = true;
        _waitingForTimer = false;
        _remaining = Duration(seconds: _room!.remainingSeconds);
        if (mounted) setState(() {});
        return;
      }
    }

    _room = info.copyWith(maxMinutes: maxMinutes);
    _timerStarted = info.timerStarted;
    _waitingForTimer = widget.session.isClient && !info.timerStarted;
    if (info.timerStarted) {
      _remaining = Duration(seconds: info.remainingSeconds);
    } else if (!wasTimerStarted) {
      _remaining = Duration(minutes: maxMinutes);
    }
    if (mounted) setState(() {});

    final newRoomId = _room?.roomId;
    if (newRoomId != null &&
        newRoomId.isNotEmpty &&
        previousRoomId != newRoomId &&
        _rtcReady) {
      await _rejoinRtc();
    }
  }

  Future<void> _rejoinRtc() async {
    await _trtc.leave();
    if (!mounted) return;
    setState(() => _rtcReady = false);
    await _joinRtc();
  }

  Future<void> _sendPing() async {
    if (!mounted || _leaving || !_timerStarted) return;
    final result = await ref.read(homeRemoteProvider).roomAction(
          widget.session.sessionId,
          'ping',
        );
    if (!mounted || result == null) return;
    if (result['timerStarted'] == true) {
      await _syncRoomInfo();
    }
  }

  void _startChatPoll() {
    _chatPoll?.cancel();
    // SSE birincil; poll yedek (prompt §10.1 — 2–3 sn, SSE yoksa).
    final interval = _sseConnected
        ? const Duration(seconds: 20)
        : const Duration(seconds: 3);
    _chatPoll = Timer.periodic(interval, (_) => _pollChat());
    unawaited(_pollChat());
  }

  Future<void> _connectRoomSse() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final storage = ref.read(tokenStorageProvider);
    await ref.read(liveFortuneRoomSseServiceProvider).connect(
          sessionId: widget.session.sessionId,
          accessToken: storage.readAccess,
          myUserId: user?.id,
          onConnected: () {
            if (!mounted) return;
            if (!_sseConnected) {
              setState(() => _sseConnected = true);
              _startChatPoll();
            }
          },
          onMessage: _onSseChatMessage,
          onRoomUpdate: _onSseRoomUpdate,
          onSessionEnded: ({endedBy}) {
            if (!mounted || _leaving) return;
            unawaited(_leave(silent: true));
          },
        );
  }

  void _onSseChatMessage(TellerChatMessage msg) {
    if (!mounted || _leaving) return;
    if (_seenChatIds.contains(msg.id)) return;
    _seenChatIds.add(msg.id);
    final created = msg.createdAt?.toUtc().toIso8601String();
    if (created != null && created.isNotEmpty) {
      _lastChatAfter = created;
    }
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSseRoomUpdate(LiveFortuneRoomInfo info) {
    if (!mounted || _leaving) return;
    final previousRoomId = _room?.roomId;
    _room = info;
    _timerStarted = info.timerStarted;
    _waitingForTimer = widget.session.isClient && !info.timerStarted;
    if (info.timerStarted) {
      _remaining = Duration(seconds: info.remainingSeconds);
    }
    setState(() {});
    if (info.roomId != null &&
        info.roomId!.isNotEmpty &&
        previousRoomId != info.roomId &&
        _rtcReady) {
      unawaited(_rejoinRtc());
    }
  }

  Future<void> _pollChat() async {
    if (!mounted || _leaving) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final remote = ref.read(homeRemoteProvider);
    final incoming = await remote.fetchTellerChatMessages(
      widget.session.sessionId,
      myUserId: user?.id,
      afterIso: _lastChatAfter,
    );
    if (!mounted || incoming.isEmpty) return;
    var changed = false;
    for (final msg in incoming) {
      if (_seenChatIds.contains(msg.id)) continue;
      _seenChatIds.add(msg.id);
      _messages.add(msg);
      final created = msg.createdAt?.toUtc().toIso8601String();
      if (created != null && created.isNotEmpty) {
        _lastChatAfter = created;
      }
      changed = true;
    }
    if (changed && mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chatScroll.hasClients) return;
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    unawaited(ref.read(liveFortuneRoomSseServiceProvider).disconnect());
    _chat.dispose();
    _chatScroll.dispose();
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
    final roomId = _room?.roomId ?? widget.session.trtcRoomId;
    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: roomId,
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
    if (!mounted || _leaving) return;
    if (widget.session.isClient) {
      await _openExtendSheet();
      if (!mounted || _leaving) return;
      if (_remaining.inSeconds > 0) {
        _startTimers();
        return;
      }
    }
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

  Future<void> _sendChat() async {
    final t = _chat.text.trim();
    if (t.isEmpty || _sendingChat) return;
    _chat.clear();
    setState(() => _sendingChat = true);
    final user = ref.read(authControllerProvider).valueOrNull;
    final ok = await ref
        .read(homeRemoteProvider)
        .sendTellerChatMessage(widget.session.sessionId, t);
    if (!mounted) return;
    setState(() => _sendingChat = false);
    if (ok) {
      final mine = TellerChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        senderId: user?.id ?? '',
        senderName: 'Sen',
        text: t,
        createdAt: DateTime.now(),
        isMine: true,
      );
      _seenChatIds.add(mine.id);
      setState(() => _messages.add(mine));
    }
    unawaited(_pollChat());
  }

  Future<void> _openTipSheet() async {
    final balance = ref.read(coinBalanceProvider).valueOrNull ??
        ref.read(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final amount = await showLiveFortuneTipSheet(
      context,
      tellerName: widget.session.teller.name,
      jetonBalance: balance,
    );
    if (!mounted || amount == null) return;
    final ok = await ref.read(homeRemoteProvider).sendTellerTip(
          sessionId: widget.session.sessionId,
          amount: amount,
          tellerId: widget.session.teller.id,
          tellerUserId: widget.session.tellerUserId,
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(coinBalanceProvider);
      setState(() => _tipThankYouAmount = amount);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _tipThankYouAmount = null);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahşiş gönderilemedi')),
      );
    }
  }

  Future<void> _openExtendSheet() async {
    final teller = widget.session.teller;
    final perMin = teller.pricePerMinute > 0 ? teller.pricePerMinute : 10;
    final balance = ref.read(coinBalanceProvider).valueOrNull ??
        ref.read(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final choice = await showLiveFortuneExtendSheet(
      context,
      jetonBalance: balance,
      jetonPerMinute: perMin,
    );
    if (!mounted || choice == null) return;
    final ok = await ref.read(homeRemoteProvider).extendFortuneSession(
          sessionId: widget.session.sessionId,
          minutes: choice.minutes,
          totalJeton: choice.jeton,
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(coinBalanceProvider);
      await _syncRoomInfo();
      if (!mounted) return;
      setState(() {
        final added = Duration(minutes: choice.minutes);
        _remaining += added;
        if (_room != null) {
          _room = _room!.copyWith(maxMinutes: _room!.maxMinutes + choice.minutes);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${choice.minutes} dakika eklendi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Süre uzatılamadı')),
      );
    }
  }

  Future<void> _confirmEnd() async {
    final ok = await showLiveFortuneCloseDialog(
      context,
      title: 'Seansı kapat?',
      message: widget.session.isClient
          ? 'Canlı fal oturumundan çıkmak istediğinize emin misiniz?'
          : 'Seansı sonlandırmak istediğinize emin misiniz?',
      confirmLabel: 'Kapat',
    );
    if (ok && mounted) await _leave();
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
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    _tick?.cancel();
    await ref.read(liveFortuneRoomSseServiceProvider).disconnect();
    await _trtc.leave();
    ref.read(videoWebrtcSignalServiceProvider).stop();

    var ended = false;
    try {
      ended = await ref
          .read(homeRemoteProvider)
          .endFortuneSession(widget.session.sessionId);
    } catch (_) {
      ended = false;
    }

    if (!mounted) return;
    if (!ended && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seans kapatma sunucuya iletilemedi; yine de çıkılıyor.',
          ),
        ),
      );
    }
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
            if (_waitingForTimer)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: ProfileGlass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      borderRadius: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Falcı hazırlanıyor…',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Süre falcı başlattığında sayılacak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_rtcReady && widget.session.isClient)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 56,
                right: 12,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 88,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TrtcLocalVideoView(
                          key: _localPreviewKey,
                          manager: _trtc,
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _rtcReady ? _trtc.switchCamera : null,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.cameraswitch_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_tipThankYouAmount != null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1450), Color(0xFF120A24)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🙏', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 10),
                          Text(
                            teller.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bahşişiniz için teşekkür ederim 🤗',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$_tipThankYouAmount Jeton',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                      blur: 4,
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
                                      _waitingForTimer ? 'Bekleniyor' : 'Bağlı',
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
                            blur: 2,
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
                            label: '+ Süre Ekle',
                            color: const Color(0xFFFFD54F),
                            foreground: Colors.black87,
                            onTap: _openExtendSheet,
                          ),
                          if (widget.session.isClient) ...[
                            const SizedBox(width: 4),
                            _TopChip(
                              label: 'Bahşiş',
                              color: AppThemeColors.accentPink,
                              icon: Icons.card_giftcard_rounded,
                              onTap: _openTipSheet,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ProfileGlass(
                      borderRadius: 16,
                      blur: 4,
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
                                'mesaj yok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                controller: _chatScroll,
                                itemCount: _messages.length,
                                itemBuilder: (_, i) {
                                  final m = _messages[i];
                                  final label = m.isMine ? 'Sen' : m.senderName;
                                  return RepaintBoundary(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$label: ',
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
