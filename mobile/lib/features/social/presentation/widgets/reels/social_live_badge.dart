import 'package:flutter/material.dart';

/// Yanıp sönen «CANLI» rozeti (TikTok/Instagram tarzı).
class SocialLiveBadge extends StatefulWidget {
  const SocialLiveBadge({super.key, this.fontSize = 12, this.viewers});

  final double fontSize;

  /// Verilirse rozetin yanında izleyici sayısı gösterilir.
  final int? viewers;

  @override
  State<SocialLiveBadge> createState() => _SocialLiveBadgeState();
}

class _SocialLiveBadgeState extends State<SocialLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.fontSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.6, vertical: fs * 0.2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF1F5A), Color(0xFFFE2C55)],
              ),
              borderRadius: BorderRadius.circular(fs),
              boxShadow: const [
                BoxShadow(color: Color(0x88FE2C55), blurRadius: 10),
              ],
            ),
            child: Text(
              'CANLI',
              style: TextStyle(
                color: Colors.white,
                fontSize: fs,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (widget.viewers != null) ...[
          SizedBox(width: fs * 0.4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.55, vertical: fs * 0.2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(fs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded, color: Colors.white, size: fs * 1.1),
                SizedBox(width: fs * 0.3),
                Text(
                  formatSocialCount(widget.viewers!),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String formatSocialCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}B';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}B';
  return '$n';
}
