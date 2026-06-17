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
import 'youtube_embed_html.dart';

/// Tam ekran YouTube arka plan (WebView iframe + Referer) — UI üstte kalır.
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
  String? _loadedSignature;
  var _loadFailed = false;

  @override
  void dispose() {
    _controller = null;
    _webView = null;
    super.dispose();
  }

  String _signature(String videoId, bool playing, int startSec) =>
      '$videoId|$playing|$startSec';

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

  Future<void> _loadVideo(RoomVideoState video) async {
    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return;

    final startSec = (video.resolvedPositionMs() / 1000).floor();
    final sig = _signature(videoId, video.isPlaying, startSec);
    if (_loadedSignature == sig && !_loadFailed) return;

    await _ensureWebView();
    final ctrl = _controller;
    if (ctrl == null) return;

    final html = YoutubeEmbedHtml.build(
      videoId: videoId,
      playing: video.isPlaying,
      startSec: startSec,
    );

    try {
      // Error 153: WebView doğrudan embed URL açarsa Referer gitmez.
      // baseUrl = canlifal.com → YouTube geçerli Referer görür.
      await ctrl.loadHtmlString(
        html,
        baseUrl: YoutubeEmbedHtml.refererOrigin,
      );
      _loadedSignature = sig;
      _loadFailed = false;
      VoiceRoomDebugLog.log('roomVideo.player.load', {
        'videoId': videoId,
        'playing': video.isPlaying,
        'startSec': startSec,
        'referer': YoutubeEmbedHtml.refererOrigin,
      });
    } catch (e, st) {
      _loadFailed = true;
      VoiceRoomDebugLog.log('roomVideo.player.load_fail', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(2).join(' '),
      });
      // Yedek: doğrudan embed + Referer header
      try {
        final embed =
            'https://www.youtube.com/embed/$videoId?autoplay=${video.isPlaying ? 1 : 0}&playsinline=1&origin=${Uri.encodeComponent(YoutubeEmbedHtml.refererOrigin)}';
        await ctrl.loadRequest(
          Uri.parse(embed),
          headers: {
            'Referer': '${YoutubeEmbedHtml.refererOrigin}/',
            'Referrer-Policy': 'strict-origin-when-cross-origin',
          },
        );
        _loadedSignature = sig;
        _loadFailed = false;
        VoiceRoomDebugLog.log('roomVideo.player.load_fallback', {
          'videoId': videoId,
        });
      } catch (e2) {
        VoiceRoomDebugLog.log('roomVideo.player.load_fallback_fail', {
          'error': e2.toString(),
        });
      }
    }
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
        _loadedSignature = null;
        _loadFailed = false;
        if (mounted) setState(() {});
        return;
      }
      unawaited(_loadVideo(next));
    });

    final videoId = YoutubeVideoId.normalize(video.videoId);
    if (videoId == null) return const SizedBox.shrink();

    if (_loadedSignature == null || _webView == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadVideo(video));
      });
    }

    final web = _webView;
    if (web == null) {
      return _thumbFallback(video);
    }

    return RepaintBoundary(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_loadFailed) _thumbFallback(video),
            Positioned.fill(child: web),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.32),
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

  Widget _thumbFallback(RoomVideoState video) {
    final thumb = video.thumbUrl?.trim();
    if (thumb == null || thumb.isEmpty) {
      return const ColoredBox(color: Color(0x66000000));
    }
    return Image.network(
      thumb,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, e, _) {
        VoiceRoomDebugLog.log('roomVideo.thumb.fail', {'error': e.toString()});
        return const ColoredBox(color: Color(0x66000000));
      },
    );
  }
}
