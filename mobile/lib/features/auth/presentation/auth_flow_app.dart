import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_navigation.dart';
import 'pages/forgot_password_page.dart';
import 'pages/login_page.dart';
import 'pages/otp_verify_page.dart';
import 'pages/register_page.dart';
import 'pages/reset_password_page.dart';
import 'widgets/premium_auth_2026/auth_premium_loading.dart';

/// Auth overlay içindeyken [AuthNavigation] go_router yerine bu navigator'ı kullanır.
class AuthOverlayScope extends InheritedWidget {
  const AuthOverlayScope({super.key, required super.child});

  @override
  bool updateShouldNotify(AuthOverlayScope oldWidget) => false;

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthOverlayScope>() != null;
}

/// Oturum kontrolü — opak yükleme katmanı (ayrı MaterialApp yok).
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

/// Oturumsuz kullanıcı — üst katman Navigator (MaterialApp.router altında).
class AuthFlowOverlay extends StatelessWidget {
  const AuthFlowOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthOverlayScope(
      child: Theme(
        data: AppTheme.dark(),
        child: Material(
          color: const Color(0xFF05050D),
          child: Navigator(
            onGenerateRoute: _onGenerateRoute,
            initialRoute: '/login',
          ),
        ),
      ),
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/login';
    switch (name) {
      case '/register':
        return AuthNavigation.instantRoute(const RegisterPage(), settings);
      case '/auth/forgot-password':
        return AuthNavigation.instantRoute(const ForgotPasswordPage(), settings);
      case '/auth/otp-verify':
        final email = settings.arguments as String?;
        return AuthNavigation.instantRoute(
          OtpVerifyPage(email: email),
          settings,
        );
      case '/auth/reset-password':
        final token = settings.arguments as String?;
        return AuthNavigation.instantRoute(
          ResetPasswordPage(token: token),
          settings,
        );
      case '/login':
      default:
        return AuthNavigation.instantRoute(
          const LoginPage(),
          const RouteSettings(name: '/login'),
        );
    }
  }
}

/// Geriye dönük isim — artık overlay; ayrı MaterialApp kullanılmaz.
@Deprecated('AuthFlowOverlay kullanın')
typedef AuthFlowApp = AuthFlowOverlay;
