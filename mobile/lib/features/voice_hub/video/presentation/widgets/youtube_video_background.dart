import 'dart:async';
import 'dart:convert';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../data/services/voice_room_debug_log.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import '../../domain/room_video_state.dart';
import '../../domain/youtube_video_id.dart';
import '../room_video_controller.dart';
import 'youtube_embed_html.dart';

/// Tam ekran YouTube arka plan (IFrame API + JS komutları) — UI üstte kalır.
class YoutubeVideoBackground extends ConsumerStatefulWidget {
  const YoutubeVideoBackground({
    super.key,
    required this.roomKey,
    this.compact = false,
  });

  final String roomKey;
  /// Koltuk altı şerit — tam genişlik, kenarlık/gölge yok.
  final bool compact;

  @override
  ConsumerState<YoutubeVideoBackground> createState() =>
      _YoutubeVideoBackgroundState();
}

class _YoutubeVideoBackgroundState extends ConsumerState<YoutubeVideoBackground> {
  WebViewController? _controller;
  WebViewWidget? _webView;
  String? _loadedVideoId;
  String? _loadedPlaybackSig;
  int _lastSeekSec = -1;
  var _playerReady = false;
  var _loadFailed = false;
  var _endingHandled = false;
  var _disposed = false;
  Timer? _endingResetTimer;

  @override
  void dispose() {
    _disposed = true;
    _endingResetTimer?.cancel();
    _controller = null;
    _webView = null;
    super.dispose();
  }

  String _playbackSig(String videoId, bool playing) => '$videoId|$playing';

  Future<void> _ensureWebView() async {
    if (_webView != null) return;

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0xFF000000));
    await controller.addJavaScriptChannel(
      'RoomVideoBridge',
      onMessageReceived: _onBridgeMessage,
    );

    late final PlatformWebViewWidgetCreationParams widgetParams;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      widgetParams = AndroidWebViewWidgetCreationParams(
        controller: controller.platform,
        displayWithHybridComposition: true,
      );
    } else {
      widgetParams = PlatformWebViewWidgetCreationParams(
        controller: controller.platform,
      );
    }

    _controller = controller;
    _webView = WebViewWidget.fromPlatformCreationParams(
      params: widgetParams,
    );
    if (mounted && !_disposed) setState(() {});
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    final msg = message.message.trim();
    if (msg == 'ready') {
      _playerReady = true;
      unawaited(_runCmd({'action': 'unmute', 'volume': 100}));
      return;
    }
    if (msg == 'ended') {
      unawaited(_onVideoEnded());
      return;
    }
    if (msg.startsWith('error:')) {
      VoiceRoomDebugLog.log('roomVideo.player.error', {'code': msg});
    }
  }

  Future<void> _onVideoEnded() async {
    if (_endingHandled) return;
    _endingHandled = true;
    VoiceRoomDebugLog.log('roomVideo.ended', {'room': widget.roomKey});
    try {
      await ref
          .read(voiceRoomLiveProvider(widget.roomKey).notifier)
          .notifyVideoTrackEnded();
    } catch (e) {
      VoiceRoomDebugLog.log('roomVideo.ended.fail', {'error': '$e'});
    }
    _endingResetTimer?.cancel();
    _endingResetTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_disposed) _endingHandled = false;
    });
  }

  Future<bool> _runCmd(Map<String, dynamic> cmd) async {
    final ctrl = _controller;
    if (ctrl == null) return false;
    try {
      final arg = jsonEncode(jsonEncode(cmd));
      final result = await ctrl.runJavaScriptReturningResult(
        'window.roomVideoCmd && window.roomVideoCmd($arg)',
      );
      return result == true || result.toString() == 'true';
    } catch (e) {
      VoiceRoomDebugLog.log('roomVideo.cmd.fail', {
        'cmd': cmd['action'],
        'error': '$e',
      });
      return false;
    }
  }

  Future<void> _loadInitialVideo(
    String videoId,
    bool playing,
    int startSec,
  ) async {
    await _ensureWebView();
    final ctrl = _controller;
    if (ctrl == null) return;

    final html = YoutubeEmbedHtml.build(
      videoId: videoId,
      playing: playing,
      startSec: startSec,
    );

    try {
      await ctrl.loadHtmlString(
        html,
        baseUrl: YoutubeEmbedHtml.refererOrigin,
      );
      _loadFailed = false;
      _playerReady = false;
      VoiceRoomDebugLog.log('roomVideo.player.load', {
        'videoId': videoId,
        'playing': playing,
        'startSec': startSec,
      });
    } catch (e, st) {
      _loadFailed = true;
      VoiceRoomDebugLog.log('roomVideo.player.load_fail', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(2).join(' '),
      });
    }
  }

  Future<void> _syncPlayback(RoomVideoState video) async {
    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return;

    final playing = video.isPlaying;
    final sig = _playbackSig(videoId, playing);
    final startSec = (video.resolvedPositionMs() / 1000).floor();

    if (_loadedVideoId != videoId) {
      _loadedVideoId = videoId;
      _loadedPlaybackSig = sig;
      _lastSeekSec = startSec;
      _endingHandled = false;
      await _loadInitialVideo(videoId, playing, startSec);
      return;
    }

    if (_webView == null) {
      await _loadInitialVideo(videoId, playing, startSec);
      _loadedVideoId = videoId;
      _loadedPlaybackSig = sig;
      _lastSeekSec = startSec;
      return;
    }

    if (_loadedPlaybackSig != sig) {
      final ok = await _runCmd({'action': playing ? 'play' : 'pause'});
      if (!ok && _playerReady) {
        await _runCmd({
          'action': 'seek',
          'sec': startSec,
          'playing': playing,
        });
      }
      _loadedPlaybackSig = sig;
      VoiceRoomDebugLog.log('roomVideo.sync.playback', {
        'playing': playing,
        'videoId': videoId,
      });
    }

    if ((startSec - _lastSeekSec).abs() > 4) {
      final ok = await _runCmd({
        'action': 'seek',
        'sec': startSec,
        'playing': playing,
      });
      if (ok) _lastSeekSec = startSec;
    }
  }

  void _teardownPlayer() {
    _controller = null;
    _webView = null;
    _loadedVideoId = null;
    _loadedPlaybackSig = null;
    _lastSeekSec = -1;
    _playerReady = false;
    _loadFailed = false;
    _endingHandled = false;
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(roomVideoControllerProvider(widget.roomKey));
    if (!video.hasActiveVideo) {
      if (_loadedVideoId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _teardownPlayer();
            setState(() {});
          }
        });
      }
      return const SizedBox.shrink();
    }

    ref.listen<RoomVideoState>(roomVideoControllerProvider(widget.roomKey),
        (prev, next) {
      if (!next.hasActiveVideo) {
        _teardownPlayer();
        if (mounted) setState(() {});
        return;
      }
      unawaited(_syncPlayback(next));
    });

    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return const SizedBox.shrink();

    if (_loadedVideoId == null || _webView == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_syncPlayback(video));
      });
    }

    final web = _webView;
    if (web == null) {
      return video.audioOnly ? const SizedBox.shrink() : _thumbFallback(video);
    }

    // !istek / müzik — tam genişlik orta arka plan; UI üstünden şeffaf geçer.
    if (video.audioOnly) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.35,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).width * 9 / 16,
                child: web,
              ),
            ),
          ),
        ),
      );
    }

    Widget player = RepaintBoundary(
      child: IgnorePointer(
        ignoring: true,
        child: widget.compact
            ? SizedBox.expand(child: web)
            : SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).width * 9 / 16,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_loadFailed) _thumbFallback(video),
                        web,
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );

    if (video.isDismissing) {
      player = ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 0.0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInCubic,
            builder: (context, factor, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: factor.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: player,
          ),
        ),
      );
    }

    return player;
  }

  Widget _thumbFallback(RoomVideoState video) {
    final thumb = video.thumbUrl?.trim();
    if (thumb == null || thumb.isEmpty) {
      return const ColoredBox(color: Color(0x66000000));
    }
    return CanlifalNetworkImage(
      url: thumb,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: const ColoredBox(color: Color(0x66000000)),
    );
  }
}
