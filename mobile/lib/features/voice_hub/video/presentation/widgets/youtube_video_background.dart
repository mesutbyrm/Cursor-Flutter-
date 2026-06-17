import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../data/services/voice_room_debug_log.dart';
import '../../domain/room_video_state.dart';
import '../../domain/youtube_video_id.dart';
import '../room_video_controller.dart';

/// Tam ekran YouTube arka plan (WebView embed) — UI katmanının altında kalır.
class YoutubeVideoBackground extends ConsumerStatefulWidget {
  const YoutubeVideoBackground({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  ConsumerState<YoutubeVideoBackground> createState() =>
      _YoutubeVideoBackgroundState();
}

class _YoutubeVideoBackgroundState extends ConsumerState<YoutubeVideoBackground> {
  WebViewController? _controller;
  WebViewWidget? _webView;
  String? _loadedVideoId;
  bool? _lastPlaying;
  var _loadFailed = false;

  @override
  void dispose() {
    _controller = null;
    _webView = null;
    super.dispose();
  }

  String _embedUrl(String videoId, {required bool playing, int startSec = 0}) {
    final autoplay = playing ? 1 : 0;
    final start = startSec.clamp(0, 86400);
    return 'https://www.youtube.com/embed/$videoId'
        '?autoplay=$autoplay&controls=0&playsinline=1&rel=0'
        '&modestbranding=1&enablejsapi=1&start=$start';
  }

  Future<void> _ensureWebView(String videoId) async {
    if (_loadedVideoId == videoId && _webView != null) return;
    _loadedVideoId = videoId;
    _loadFailed = false;

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
    await controller.setBackgroundColor(const Color(0x00000000));

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
    if (mounted) setState(() {});
  }

  Future<void> _syncPlayback(RoomVideoState video) async {
    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return;

    await _ensureWebView(videoId);
    final ctrl = _controller;
    if (ctrl == null) return;

    final startSec = (video.resolvedPositionMs() / 1000).floor();
    final needsReload = _lastPlaying != video.isPlaying ||
        (_loadedVideoId == videoId && _lastPlaying == null);

    if (needsReload || _loadedVideoId != videoId) {
      try {
        await ctrl.loadRequest(
          Uri.parse(_embedUrl(videoId, playing: video.isPlaying, startSec: startSec)),
        );
        VoiceRoomDebugLog.log('roomVideo.player.load', {
          'videoId': videoId,
          'playing': video.isPlaying,
          'startSec': startSec,
        });
        _loadFailed = false;
      } catch (e, st) {
        _loadFailed = true;
        VoiceRoomDebugLog.log('roomVideo.player.load_fail', {
          'error': e.toString(),
          'stack': st.toString().split('\n').take(2).join(' '),
        });
      }
    }
    _lastPlaying = video.isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(roomVideoControllerProvider(widget.roomKey));
    if (!video.hasActiveVideo) {
      return const SizedBox.shrink();
    }

    ref.listen<RoomVideoState>(roomVideoControllerProvider(widget.roomKey),
        (prev, next) {
      if (!next.hasActiveVideo) {
        _controller = null;
        _webView = null;
        _loadedVideoId = null;
        _lastPlaying = null;
        _loadFailed = false;
        if (mounted) setState(() {});
        return;
      }
      unawaited(_syncPlayback(next));
    });

    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return const SizedBox.shrink();

    if (_loadedVideoId != videoId || _webView == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_syncPlayback(video));
      });
    } else if (_lastPlaying != video.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_syncPlayback(video));
      });
    }

    final web = _webView;
    if (web == null || _loadFailed) {
      return _loadingPlaceholder(video);
    }

    return RepaintBoundary(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: web),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingPlaceholder(RoomVideoState video) {
    final thumb = video.thumbUrl?.trim();
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.transparent,
        child: thumb != null && thumb.isNotEmpty
            ? Image.network(
                thumb,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, e, _) {
                  VoiceRoomDebugLog.log('roomVideo.thumb.fail', {
                    'error': e.toString(),
                  });
                  return const SizedBox.shrink();
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
