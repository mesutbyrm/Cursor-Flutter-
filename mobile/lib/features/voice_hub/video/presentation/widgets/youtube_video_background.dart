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
    this.fillBackground = false,
  });

  final String roomKey;
  /// Koltuk altı şerit — tam genişlik, kenarlık/gölge yok.
  final bool compact;
  /// Video isteğinde oda arka planında tam ekran YouTube.
  final bool fillBackground;

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
  var _visualOnlyActive = false;
  Timer? _endingResetTimer;
  Future<void>? _ensureWebViewFuture;

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
    final pending = _ensureWebViewFuture;
    if (pending != null) {
      await pending;
      return;
    }
    final future = _createWebView();
    _ensureWebViewFuture = future;
    try {
      await future;
    } finally {
      if (identical(_ensureWebViewFuture, future)) {
        _ensureWebViewFuture = null;
      }
    }
  }

  Future<void> _createWebView() async {
    if (_webView != null || _disposed) return;

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
      if (!_visualOnlyActive) {
        unawaited(_runCmd({'action': 'unmute', 'volume': 100}));
      }
      return;
    }
    if (msg == 'playing') {
      if (!_visualOnlyActive) {
        unawaited(_runCmd({'action': 'unmute', 'volume': 100}));
      }
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
    int startSec, {
    required bool visualOnly,
  }) async {
    _visualOnlyActive = visualOnly;
    await _ensureWebView();
    final ctrl = _controller;
    if (ctrl == null) return;

    final html = YoutubeEmbedHtml.build(
      videoId: videoId,
      playing: playing,
      startSec: startSec,
      visualOnly: visualOnly,
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
      if (visualOnly) {
        unawaited(
          ref
              .read(voiceRoomLiveProvider(widget.roomKey).notifier)
              .fallbackVideoToAudioOnly(),
        );
      }
    }
  }

  Future<void> _syncPlayback(RoomVideoState video) async {
    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return;

    final playing = video.isPlaying;
    final sig = _playbackSig(videoId, playing);
    final startSec = (video.resolvedPositionMs() / 1000).floor();
    final visualOnly = video.showsVideo;

    if (_loadedVideoId != videoId) {
      _loadedVideoId = videoId;
      _loadedPlaybackSig = sig;
      _lastSeekSec = startSec;
      _endingHandled = false;
      await _loadInitialVideo(videoId, playing, startSec, visualOnly: visualOnly);
      return;
    }

    if (_webView == null) {
      await _loadInitialVideo(videoId, playing, startSec, visualOnly: visualOnly);
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
      if (video.audioOnly) {
        return const SizedBox(width: 1, height: 1);
      }
      // Video henüz hazır değil — sınırlı yükseklikli şerit thumb (Column güvenli).
      final w = MediaQuery.sizeOf(context).width;
      return SizedBox(
        width: double.infinity,
        height: (w * 9 / 16).clamp(140.0, 230.0),
        child: _thumbFallback(video),
      );
    }

    if (video.audioOnly) {
      return RepaintBoundary(
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: SizedBox(
              width: 1,
              height: 1,
              child: web,
            ),
          ),
        ),
      );
    }

    // Video isteği (!istek video): arka planda tam ekran veya koltuk altı şerit.
    final width = MediaQuery.sizeOf(context).width;
    final stripHeight = (width * 9 / 16).clamp(140.0, 230.0);
    final videoChild = RepaintBoundary(
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_loadFailed) _thumbFallback(video),
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                child: SizedBox(
                  width: width,
                  height: width * 9 / 16,
                  child: web,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.fillBackground && !widget.compact) {
      return SizedBox.expand(child: videoChild);
    }

    return RepaintBoundary(
      child: IgnorePointer(
        child: SizedBox(
          width: double.infinity,
          height: stripHeight,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_loadFailed) _thumbFallback(video),
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: width,
                    height: width * 9 / 16,
                    child: web,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
