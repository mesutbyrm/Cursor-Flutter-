import 'package:flutter/material.dart';

/// Referans PK üst bar — geri + ortada PK geri sayım.
class LivePkReferenceTopBar extends StatelessWidget {
  const LivePkReferenceTopBar({
    super.key,
    required this.timer,
    this.onBack,
    this.viewerCount = 0,
    this.trailing,
    this.brandTitle,
  });

  final Widget timer;
  final VoidCallback? onBack;
  final int viewerCount;
  final Widget? trailing;
  final String? brandTitle;

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
              Colors.black.withValues(alpha: 0.78),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, top + 4, 8, 12),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              else
                const SizedBox(width: 8),
              if (brandTitle != null && brandTitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    brandTitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              Expanded(child: Center(child: timer)),
              if (viewerCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmtCount(viewerCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              trailing ?? const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
