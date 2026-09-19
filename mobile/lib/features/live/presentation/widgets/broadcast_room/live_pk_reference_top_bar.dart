import 'package:flutter/material.dart';

import 'live_pk_viewer_strip.dart';
import '../../../domain/entities/live_stream_viewer.dart';

/// Referans PK üst bar — marka, izleyiciler, kapat.
class LivePkReferenceTopBar extends StatelessWidget {
  const LivePkReferenceTopBar({
    super.key,
    this.onBack,
    this.onClose,
    this.viewerCount = 0,
    this.viewers = const [],
    this.centerTimer,
  });

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final int viewerCount;
  final List<LiveStreamViewer> viewers;

  /// Başlık ortasında gösterilecek PK sayaç rozeti (opsiyonel).
  final Widget? centerTimer;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.82),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(2, top + 2, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              else
                const SizedBox(width: 4),
              _BrandMark(),
              if (centerTimer != null) ...[
                const Spacer(),
                centerTimer!,
              ],
              const Spacer(),
              LivePkViewerStrip(
                viewers: viewers,
                totalCount: viewerCount,
                showRankBadges: true,
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  tooltip: 'Kapat',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFB832FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB832FF).withValues(alpha: 0.45),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CanlıFal 💜',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                height: 1.1,
              ),
            ),
            Text(
              'Hayata Fal Kat 💜',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
