import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';

/// Giriş / kayıt — 2026 liquid glass + immersive mesh.
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
  final bool useAppIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumImmersiveBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AuthGlowOverlay(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LiquidGlass(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(16),
                          blur: 14,
                          onTap: onBack ?? () => Navigator.of(context).maybePop(),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: PremiumMotion.listPhysics,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            children: [
                              CanlifalBrandLogo.appIcon(
                                size: useAppIcon ? 96 : 112,
                              ),
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
      ),
    );
  }
}

class _AuthGlowOverlay extends StatelessWidget {
  const _AuthGlowOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.1,
                colors: [
                  const Color(0xFF4C1D95).withValues(alpha: 0.45),
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
                  AppColors.accentPurple.withValues(alpha: 0.2),
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
    return LiquidGlassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      elevated: true,
      child: child,
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: PremiumTypography.displayMedium(context),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: PremiumTypography.body(context),
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
  final t = Premium2026Tokens.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: t.glassBorder.withValues(alpha: 0.4)),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: const TextStyle(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(
      color: AppColors.textMuted.withValues(alpha: 0.7),
      fontSize: 14,
    ),
    prefixIcon: Icon(prefixIcon, color: AppColors.accentPurple, size: 22),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.35),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF9D6BFF), width: 1.5),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: AppColors.liveRed.withValues(alpha: 0.8)),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.liveRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: loading ? () {} : (onPressed ?? () {}),
      child: AnimatedOpacity(
        opacity: onPressed != null || loading ? 1 : 0.5,
        duration: PremiumMotion.fast,
        child: LiquidGlass(
          padding: const EdgeInsets.symmetric(vertical: 16),
          borderRadius: BorderRadius.circular(18),
          blur: 12,
          gradientBorder: const LinearGradient(
            colors: [Color(0xFF9D6BFF), Color(0xFF7C3AED), Color(0xFF5B21B6)],
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
    return LiquidGlass(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      blur: 14,
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
              style: PremiumTypography.body(context).copyWith(fontSize: 13),
            ),
          ),
        ],
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
          child: Divider(color: AppColors.textMuted.withValues(alpha: 0.35)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: PremiumTypography.label(context),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textMuted.withValues(alpha: 0.35)),
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
