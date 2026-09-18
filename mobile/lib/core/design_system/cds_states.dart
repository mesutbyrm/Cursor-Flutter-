import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';
import '../ui/premium/premium_empty_hint.dart';
import '../widgets/app_error_view.dart';
import 'cds_skeleton.dart';
import 'cds_typography.dart';

/// Hafif yükleme göstergesi — sürekli dönen büyük spinner yerine.
class CdsInlineSpinner extends StatefulWidget {
  const CdsInlineSpinner({
    super.key,
    this.size = 22,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<CdsInlineSpinner> createState() => _CdsInlineSpinnerState();
}

class _CdsInlineSpinnerState extends State<CdsInlineSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _ArcPainter(
              progress: _c.value,
              color: color,
              strokeWidth: 2.2,
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(strokeWidth),
      progress * 6.28,
      2.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// CDS yükleme / boş / hata durumları.
abstract final class CdsLoading {
  static Widget centered({String? label, bool skeleton = false}) {
    if (skeleton) {
      return CdsSkeleton.feed(postCount: 2);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CdsInlineSpinner(),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label),
          ],
        ],
      ),
    );
  }

  static Widget feed({int count = 3}) => CdsSkeleton.feed(postCount: count);

  static Widget membership() => CdsSkeleton.membershipCatalog();

  static Widget profile() => CdsSkeleton.profileHeader();
}

abstract final class CdsEmpty {
  static Widget hint({
    required String message,
    VoidCallback? onRetry,
  }) {
    return PremiumEmptyHint(message: message, onRetry: onRetry);
  }
}

abstract final class CdsError {
  static Widget view({
    required BuildContext context,
    required Object error,
    VoidCallback? onRetry,
  }) {
    // `error.toString()` kullanıcıya ham DioException/stack metni gösteriyordu.
    // `fromError` ApiException.userMessage'a gider — o helper zaten "ham
    // DioException veya toString göstermez" sözleşmesini taşıyor.
    return AppErrorView.fromError(error, onRetry: onRetry);
  }

  static Widget inline(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: CdsTypography.body(context),
        textAlign: TextAlign.center,
      ),
    );
  }
}
