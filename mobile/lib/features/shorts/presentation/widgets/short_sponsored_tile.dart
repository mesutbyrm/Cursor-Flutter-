import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/video/safe_video_layout.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/shorts_feed_entry.dart';
import '../providers/shorts_playback_providers.dart';
import '../utils/short_video_player_util.dart';
import 'shorts_premium_theme.dart';

/// Sponsorlu video — normal akış görünümü + «Sponsorlu» etiketi, geçilebilir.
class ShortSponsoredTile extends ConsumerStatefulWidget {
  const ShortSponsoredTile({
    super.key,
    required this.ad,
    required this.isActive,
    required this.onSkip,
  });

  final ShortSponsoredAd ad;
  final bool isActive;
  final VoidCallback onSkip;

  @override
  ConsumerState<ShortSponsoredTile> createState() => _ShortSponsoredTileState();
}

class _ShortSponsoredTileState extends ConsumerState<ShortSponsoredTile> {
  VideoPlayerController? _controller;
  var _loading = true;
  var _skipSec = 0;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant ShortSponsoredTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  Future<void> _init() async {
    try {
      final c = await createShortVideoController(
        url: widget.ad.videoUrl,
        dio: ref.read(dioProvider),
        fastStart: true,
      );
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      setState(() => _loading = false);
      _syncPlayback();
      _startSkipCountdown();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startSkipCountdown() {
    _skipTimer?.cancel();
    _skipSec = 0;
    _skipTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _skipSec++);
    });
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive) {
      c.setPlaybackSpeed(ref.read(shortPlaybackSpeedProvider));
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final canSkip = _skipSec >= widget.ad.skipAfterSec;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_loading)
          ColoredBox(color: ShortsPremiumTheme.feedBackground(context))
        else if (c != null && c.value.isInitialized)
          SafeCoverVideoPlayer(controller: c)
        else
          ColoredBox(color: ShortsPremiumTheme.feedBackground(context)),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 56,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sponsorlu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.ad.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (widget.ad.ctaUrl != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(widget.ad.ctaUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(widget.ad.ctaLabel),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 52,
          right: 14,
          child: TextButton(
            onPressed: canSkip ? widget.onSkip : null,
            style: TextButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
            ),
            child: Text(
              canSkip
                  ? 'Geç'
                  : 'Geç (${widget.ad.skipAfterSec - _skipSec}s)',
            ),
          ),
        ),
      ],
    );
  }
}
