import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/chat_room_providers.dart';

/// Ses akışı başarısız olunca sürüklenebilir mini YouTube oynatıcı.
class VoiceRoomDjVideoFallback extends ConsumerStatefulWidget {
  const VoiceRoomDjVideoFallback({super.key});

  @override
  ConsumerState<VoiceRoomDjVideoFallback> createState() =>
      _VoiceRoomDjVideoFallbackState();
}

class _VoiceRoomDjVideoFallbackState
    extends ConsumerState<VoiceRoomDjVideoFallback> {
  static const _panelW = 108.0;
  static const _videoSize = 96.0;

  WebViewController? _web;
  String? _loadedVideoId;
  Offset _offset = const Offset(12, 120);
  var _placed = false;
  var _embedPlaying = true;

  @override
  void dispose() {
    unawaited(_web?.loadRequest(Uri.parse('about:blank')));
    super.dispose();
  }

  void _placeIfNeeded(BuildContext context) {
    if (_placed) return;
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    _offset = Offset(
      (size.width - _panelW - 12).clamp(8.0, size.width - _panelW),
      (size.height - bottomInset - 220).clamp(80.0, size.height - 200),
    );
    _placed = true;
  }

  Future<void> _loadEmbed(String videoId) async {
    if (_loadedVideoId == videoId && _web != null) return;
    _loadedVideoId = videoId;
    final embed =
        'https://www.youtube.com/embed/$videoId'
        '?autoplay=1&playsinline=1&controls=0&modestbranding=1&rel=0'
        '&enablejsapi=1';
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(embed));
    if (!mounted) return;
    setState(() {
      _web = controller;
      _embedPlaying = true;
    });
  }

  Future<void> _togglePlay(String videoId) async {
    final player = ref.read(voiceRoomDjPlayerProvider);
    final pb = player.playback.value;
    if (pb.playing) {
      await player.pauseLocal();
      setState(() => _embedPlaying = false);
      return;
    }
    if (pb.duration > Duration.zero) {
      await player.resumeLocal();
      setState(() => _embedPlaying = true);
      return;
    }
    setState(() => _embedPlaying = true);
    await _loadEmbed(videoId);
  }

  Future<void> _stop(String videoId) async {
    await ref.read(voiceRoomDjPlayerProvider).stop();
    setState(() => _embedPlaying = false);
    await _loadEmbed(videoId);
  }

  void _close() {
    unawaited(ref.read(voiceRoomDjPlayerProvider).stop());
    ref.read(voiceRoomDjVideoFallbackProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = ref.watch(voiceRoomDjVideoFallbackProvider);
    if (videoId == null || videoId.isEmpty) {
      _web = null;
      _loadedVideoId = null;
      return const SizedBox.shrink();
    }

    _placeIfNeeded(context);

    ref.listen(voiceRoomDjVideoFallbackProvider, (prev, next) {
      if (next != null && next.isNotEmpty && next != _loadedVideoId) {
        unawaited(_loadEmbed(next));
      }
      if (next == null || next.isEmpty) {
        _web = null;
        _loadedVideoId = null;
      }
    });

    if (_loadedVideoId != videoId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadEmbed(videoId));
      });
    }

    final thumb = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A0B2E),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onPanUpdate: (d) {
                final size = MediaQuery.sizeOf(context);
                setState(() {
                  _offset = Offset(
                    (_offset.dx + d.delta.dx).clamp(0.0, size.width - _panelW),
                    (_offset.dy + d.delta.dy).clamp(0.0, size.height - 160),
                  );
                });
              },
              child: Container(
                width: _panelW,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.drag_indicator_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Video yedek',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: _videoSize,
                        height: _videoSize,
                        child: _web != null
                            ? WebViewWidget(controller: _web!)
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                  ),
                                  const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: _panelW,
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniControl(
                    icon: _embedPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFFFF9800),
                    tooltip: _embedPlaying ? 'Duraklat' : 'Oynat',
                    onTap: () => unawaited(_togglePlay(videoId)),
                  ),
                  _MiniControl(
                    icon: Icons.stop_rounded,
                    color: const Color(0xFF546E7A),
                    tooltip: 'Durdur',
                    onTap: () => unawaited(_stop(videoId)),
                  ),
                  _MiniControl(
                    icon: Icons.close_rounded,
                    color: const Color(0xFFC62828),
                    tooltip: 'Kapat',
                    onTap: _close,
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

class _MiniControl extends StatelessWidget {
  const _MiniControl({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
