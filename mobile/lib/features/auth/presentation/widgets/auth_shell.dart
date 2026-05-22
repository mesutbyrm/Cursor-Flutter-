import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Giriş / kayıt — mockup: koyu mor arka plan, şeffaf logo, mor CTA.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.useAppIcon = false,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  /// Kayıt ekranında kare uygulama ikonu; girişte yatay logo.
  final bool useAppIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthMysticBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textSecondary,
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            if (useAppIcon)
                              const CanlifalBrandLogo.appIcon(size: 88)
                            else
                              const CanlifalBrandLogo.horizontal(height: 108),
                            const SizedBox(height: 28),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMysticBackdrop extends StatelessWidget {
  const _AuthMysticBackdrop();

  @override
  Widget build(BuildContext context) {
    return DiscoverBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.1,
                colors: [
                  const Color(0xFF4C1D95).withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, 0.9),
                radius: 0.75,
                colors: [
                  AppColors.accentPurple.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: child,
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CanlifalAuthTitle(title),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AuthBrandHeader(title: title, subtitle: subtitle);
  }
}

InputDecoration authInputDecoration({
  required String labelText,
  required IconData prefixIcon,
  String? hintText,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: AppColors.accentPurple.withValues(alpha: 0.35),
    ),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: const TextStyle(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: TextStyle(
      color: AppColors.textMuted.withValues(alpha: 0.7),
      fontSize: 14,
    ),
    prefixIcon: Icon(prefixIcon, color: AppColors.accentPurple, size: 22),
    filled: true,
    fillColor: const Color(0xFF1A1030).withValues(alpha: 0.65),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF9D6BFF), width: 1.5),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(
        color: AppColors.liveRed.withValues(alpha: 0.8),
      ),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.liveRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9D6BFF),
      Color(0xFF7C3AED),
      Color(0xFF5B21B6),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || loading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled ? _purpleGradient : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            boxShadow: enabled
                ? AppColors.glowShadow(
                    const Color(0xFF7C3AED),
                    blur: 20,
                  )
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.accentCyan.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accentCyan.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.accentCyan.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFC4B5FD).withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
