import 'package:flutter/material.dart';

/// Premium 3D karo — cam çerçeve, kontrollü neon kenar, decode önbelleği.
class PremiumGlassImage extends StatelessWidget {
  const PremiumGlassImage({
    super.key,
    required this.assetPath,
    this.fallbackAssetPath,
    this.borderRadius = 14,
    this.glowColor,
    this.fit = BoxFit.cover,
    this.cacheWidth = 240,
    this.semanticLabel,
    this.fallbackIcon,
  });

  final String assetPath;
  final String? fallbackAssetPath;
  final double borderRadius;
  final Color? glowColor;
  final BoxFit fit;
  final int cacheWidth;
  final String? semanticLabel;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(borderRadius);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: glow.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AssetLayer(
                path: assetPath,
                fit: fit,
                cacheWidth: cacheWidth,
                fallbackPath: fallbackAssetPath,
                fallbackIcon: fallbackIcon,
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetLayer extends StatelessWidget {
  const _AssetLayer({
    required this.path,
    required this.fit,
    required this.cacheWidth,
    this.fallbackPath,
    this.fallbackIcon,
  });

  final String path;
  final BoxFit fit;
  final int cacheWidth;
  final String? fallbackPath;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) {
        if (fallbackPath != null && fallbackPath != path) {
          return Image.asset(
            fallbackPath!,
            fit: fit,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) => _iconFallback(context),
          );
        }
        return _iconFallback(context);
      },
    );
  }

  Widget _iconFallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          fallbackIcon ?? Icons.auto_awesome_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
