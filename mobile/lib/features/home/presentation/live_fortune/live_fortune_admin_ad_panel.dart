import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/home_banner_entity.dart';
import '../providers/home_providers.dart';

/// Admin panelinden gelen banner/reklam — bekleme ve geçiş ekranlarında.
class LiveFortuneAdminAdPanel extends ConsumerStatefulWidget {
  const LiveFortuneAdminAdPanel({
    super.key,
    this.countdownSeconds,
    this.onCountdownFinished,
    this.subtitle = 'Canlı fal deneyiminiz birazdan başlayacak!',
  });

  /// null ise geri sayım gösterilmez.
  final int? countdownSeconds;
  final VoidCallback? onCountdownFinished;
  final String subtitle;

  @override
  ConsumerState<LiveFortuneAdminAdPanel> createState() =>
      _LiveFortuneAdminAdPanelState();
}

class _LiveFortuneAdminAdPanelState extends ConsumerState<LiveFortuneAdminAdPanel> {
  var _remaining = 0;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds ?? 0;
    if (_remaining > 0) {
      Future<void>.delayed(const Duration(seconds: 1), _tick);
    }
  }

  void _tick() {
    if (!mounted || _finished) return;
    if (_remaining <= 1) {
      setState(() {
        _remaining = 0;
        _finished = true;
      });
      widget.onCountdownFinished?.call();
      return;
    }
    setState(() => _remaining -= 1);
    Future<void>.delayed(const Duration(seconds: 1), _tick);
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(homeBannersProvider);
    final banner = bannersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list.first : null,
      orElse: () => null,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _gradientFromBanner(banner),
        image: banner?.imageUrl != null && banner!.imageUrl!.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(banner.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.45),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            if (banner?.imageUrl == null || banner!.imageUrl!.isEmpty)
              const Icon(
                Icons.campaign_rounded,
                color: Color(0xFFFFD54F),
                size: 36,
              ),
            if (banner?.imageUrl == null || banner!.imageUrl!.isEmpty)
              const SizedBox(height: 10),
            Text(
              banner?.title.trim().isNotEmpty == true
                  ? banner!.title
                  : 'Reklam',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (banner?.subtitle != null && banner!.subtitle!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  banner.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                banner?.ctaLabel?.trim().isNotEmpty == true
                    ? banner!.ctaLabel!
                    : '🔮 Canlifal Premium 🔮',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.countdownSeconds != null)
              Text(
                _remaining > 0
                    ? 'Reklam: ${_remaining}s'
                    : 'Bağlantı kuruluyor…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
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
    );
  }

  LinearGradient _gradientFromBanner(HomeBannerEntity? banner) {
    if (banner != null && banner.gradient.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: banner.gradient
            .map((c) => Color(0xFF000000 | (c & 0xFFFFFF)))
            .toList(growable: false),
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB832FF), Color(0xFFFF0080)],
    );
  }
}
