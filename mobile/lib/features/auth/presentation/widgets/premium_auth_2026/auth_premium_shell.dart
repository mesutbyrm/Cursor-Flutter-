import 'package:flutter/material.dart';

import 'auth_plain_shell.dart';

/// Giriş / kayıt — tüm platformlarda opak kabuk (blur/cam Android'de gri ekran yapıyordu).
class AuthPremiumShell extends StatelessWidget {
  const AuthPremiumShell({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.heroLogo = false,
    this.topTitle,
    this.topSubtitle,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final bool heroLogo;
  final String? topTitle;
  final String? topSubtitle;

  @override
  Widget build(BuildContext context) {
    return AuthPlainShell(
      showBack: showBack,
      onBack: onBack,
      heroLogo: heroLogo,
      topTitle: topTitle,
      topSubtitle: topSubtitle,
      child: child,
    );
  }
}
