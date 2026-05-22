import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'canlifal_logo.dart';

/// Mockup uyumlu marka görselleri — şeffaf PNG, yoksa vektör yedek.
class CanlifalBrandLogo extends StatelessWidget {
  const CanlifalBrandLogo.horizontal({
    super.key,
    this.height = 120,
  })  : _variant = _BrandVariant.horizontal,
        size = null;

  const CanlifalBrandLogo.appIcon({
    super.key,
    this.size = 96,
  })  : _variant = _BrandVariant.appIcon,
        height = null;

  final _BrandVariant _variant;
  final double? height;
  final double? size;

  static const _horizontalAsset = 'assets/brand/canlifal_logo_horizontal.png';
  static const _iconAsset = 'assets/brand/canlifal_app_icon.png';

  @override
  Widget build(BuildContext context) {
    if (_variant == _BrandVariant.horizontal) {
      return Image.asset(
        _horizontalAsset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, e, s) => CanlifalLogo(
          size: (height ?? 120) * 0.55,
          showWordmark: true,
        ),
      );
    }

    final s = size ?? 96;
    return Image.asset(
      _iconAsset,
      width: s,
      height: s,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, e, st) => CanlifalLogo(size: s, showWordmark: false),
    );
  }
}

enum _BrandVariant { horizontal, appIcon }

/// Giriş / kayıt başlığı — mockup mor gradyan.
class CanlifalAuthTitle extends StatelessWidget {
  const CanlifalAuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => const LinearGradient(
        colors: [
          Color(0xFFE9D5FF),
          AppColors.accentPurple,
          Color(0xFF7C3AED),
        ],
      ).createShader(b),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 28,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
