import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';

/// Neon gradient CTA — TikTok / Discord seviyesi.
class AuthNeonButton extends StatefulWidget {
  const AuthNeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF2D7A),
      Color(0xFF9B4DFF),
      Color(0xFF5B21B6),
    ],
  );

  @override
  State<AuthNeonButton> createState() => _AuthNeonButtonState();
}

class _AuthNeonButtonState extends State<AuthNeonButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null || widget.loading;

    return GestureDetector(
      onTapDown: enabled && !widget.loading ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled && !widget.loading ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: PremiumMotion.fast,
        curve: PremiumMotion.spring,
        child: AnimatedContainer(
          duration: PremiumMotion.medium,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: enabled ? AuthNeonButton._gradient : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF9B4DFF).withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppThemeColors.accentPink.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
