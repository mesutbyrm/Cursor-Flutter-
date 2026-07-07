import 'package:flutter/material.dart';

import 'voice_rooms_ui_tokens.dart';

/// Cam efektli yeniden kullanılabilir kart kabı.
class VoiceGlassContainer extends StatelessWidget {
  const VoiceGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = VoiceRoomsUiTokens.radiusMd,
    this.blur = 18,
    this.tint,
    this.glowColor,
    this.onTap,
    this.heroTag,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? glowColor;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget content = VoiceRoomsUiTokens.glassBlur(
      radius: radius,
      sigma: blur,
      padding: padding ?? const EdgeInsets.all(VoiceRoomsUiTokens.gapMd),
      decoration: VoiceRoomsUiTokens.glass(radius: radius, tint: tint).copyWith(
        boxShadow: glowColor != null
            ? VoiceRoomsUiTokens.glowShadow(glowColor!, blur: 20)
            : null,
      ),
      child: child,
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.2),
          highlightColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.1),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
