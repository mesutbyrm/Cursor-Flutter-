import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'pages/forgot_password_page.dart';
import 'pages/login_page.dart';
import 'pages/otp_verify_page.dart';
import 'pages/register_page.dart';
import 'pages/reset_password_page.dart';
import 'widgets/premium_auth_2026/auth_premium_loading.dart';

/// Auth overlay sayfa hedefleri — iç [Navigator] yok (yetim ModalBarrier önlenir).
enum AuthOverlayRoute {
  login,
  register,
  forgotPassword,
  otpVerify,
  resetPassword,
}

/// Overlay içi sayfa geçişi — [Navigator.push] / ModalRoute kullanılmaz.
class AuthOverlayController extends InheritedWidget {
  const AuthOverlayController({
    super.key,
    required this.route,
    required this.onNavigate,
    required this.onBack,
    required super.child,
  });

  final AuthOverlayRoute route;
  final void Function(AuthOverlayRoute route, {String? email, String? token})
      onNavigate;
  final VoidCallback onBack;

  static AuthOverlayController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthOverlayController>();

  @override
  bool updateShouldNotify(AuthOverlayController oldWidget) =>
      route != oldWidget.route;
}

/// Auth overlay içindeyken [AuthNavigation] go_router yerine bu kapsamı kullanır.
class AuthOverlayScope extends InheritedWidget {
  const AuthOverlayScope({super.key, required super.child});

  @override
  bool updateShouldNotify(AuthOverlayScope oldWidget) => false;

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthOverlayScope>() != null;
}

/// Oturum kontrolü — opak yükleme katmanı.
class AuthBootstrapOverlay extends StatelessWidget {
  const AuthBootstrapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFF05050D),
      child: Center(child: AuthPremiumLoading(size: 52)),
    );
  }
}

/// Oturumsuz kullanıcı — üst katman (iç Navigator YOK).
class AuthFlowOverlay extends StatefulWidget {
  const AuthFlowOverlay({super.key});

  @override
  State<AuthFlowOverlay> createState() => _AuthFlowOverlayState();
}

class _AuthFlowOverlayState extends State<AuthFlowOverlay> {
  AuthOverlayRoute _route = AuthOverlayRoute.login;
  String? _email;
  String? _resetToken;

  void _navigate(AuthOverlayRoute route, {String? email, String? token}) {
    setState(() {
      _route = route;
      if (email != null) _email = email;
      if (token != null) _resetToken = token;
    });
  }

  void _back() {
    setState(() => _route = AuthOverlayRoute.login);
  }

  Widget _pageFor(AuthOverlayRoute route) {
    switch (route) {
      case AuthOverlayRoute.login:
        return const LoginPage();
      case AuthOverlayRoute.register:
        return const RegisterPage();
      case AuthOverlayRoute.forgotPassword:
        return const ForgotPasswordPage();
      case AuthOverlayRoute.otpVerify:
        return OtpVerifyPage(email: _email);
      case AuthOverlayRoute.resetPassword:
        return ResetPasswordPage(token: _resetToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthOverlayScope(
      child: AuthOverlayController(
        route: _route,
        onNavigate: _navigate,
        onBack: _back,
        child: Theme(
          data: AppTheme.dark(),
          child: Material(
            color: const Color(0xFF05050D),
            child: _pageFor(_route),
          ),
        ),
      ),
    );
  }
}

@Deprecated('AuthFlowOverlay kullanın')
typedef AuthFlowApp = AuthFlowOverlay;
