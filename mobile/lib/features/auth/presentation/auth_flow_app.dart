import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations_config.dart';
import '../../../core/scroll/modern_social_scroll_behavior.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_navigation.dart';
import 'pages/forgot_password_page.dart';
import 'pages/login_page.dart';
import 'pages/otp_verify_page.dart';
import 'pages/register_page.dart';
import 'pages/reset_password_page.dart';

/// Oturumsuz kullanıcı — go_router YOK (ModalBarrier / gri katman riski sıfır).
class AuthFlowApp extends ConsumerWidget {
  const AuthFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Canlifal',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ModernSocialScrollBehavior(),
      locale: AppLocalizationsConfig.locale,
      supportedLocales: AppLocalizationsConfig.supportedLocales,
      localizationsDelegates: AppLocalizationsConfig.delegates,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      onGenerateRoute: _onGenerateRoute,
      initialRoute: '/login',
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
