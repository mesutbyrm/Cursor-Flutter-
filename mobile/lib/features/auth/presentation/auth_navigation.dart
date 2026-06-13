import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_flow_app.dart';
import 'pages/forgot_password_page.dart';
import 'pages/login_page.dart';
import 'pages/otp_verify_page.dart';
import 'pages/register_page.dart';
import 'pages/reset_password_page.dart';

/// Auth ekranları — overlay state veya go_router (derin link).
abstract final class AuthNavigation {
  static bool _useOverlay(BuildContext context) =>
      AuthOverlayScope.isActive(context);

  static bool _hasGoRouter(BuildContext context) =>
      !_useOverlay(context) && GoRouter.maybeOf(context) != null;

  static Route<T> instantRoute<T>(Widget child, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, _, _) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static void toLogin(BuildContext context) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onNavigate(AuthOverlayRoute.login);
      return;
    }
    if (_hasGoRouter(context)) {
      context.go('/login');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      instantRoute(const LoginPage(), const RouteSettings(name: '/login')),
      (_) => false,
    );
  }

  static void toRegister(BuildContext context) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onNavigate(AuthOverlayRoute.register);
      return;
    }
    if (_hasGoRouter(context)) {
      context.push('/register');
      return;
    }
    Navigator.of(context).push(
      instantRoute(const RegisterPage(), const RouteSettings(name: '/register')),
    );
  }

  static void toForgotPassword(BuildContext context) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onNavigate(AuthOverlayRoute.forgotPassword);
      return;
    }
    if (_hasGoRouter(context)) {
      context.push('/auth/forgot-password');
      return;
    }
    Navigator.of(context).push(
      instantRoute(
        const ForgotPasswordPage(),
        const RouteSettings(name: '/auth/forgot-password'),
      ),
    );
  }

  static void toOtpVerify(BuildContext context, {String? email}) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onNavigate(AuthOverlayRoute.otpVerify, email: email);
      return;
    }
    if (_hasGoRouter(context)) {
      context.push('/auth/otp-verify', extra: email);
      return;
    }
    Navigator.of(context).push(
      instantRoute(
        OtpVerifyPage(email: email),
        RouteSettings(name: '/auth/otp-verify', arguments: email),
      ),
    );
  }

  static void toResetPassword(BuildContext context, {String? token}) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onNavigate(AuthOverlayRoute.resetPassword, token: token);
      return;
    }
    if (_hasGoRouter(context)) {
      context.go(
        '/auth/reset-password?token=${Uri.encodeQueryComponent(token ?? '')}',
      );
      return;
    }
    Navigator.of(context).push(
      instantRoute(
        ResetPasswordPage(token: token),
        RouteSettings(
          name: '/auth/reset-password',
          arguments: token,
        ),
      ),
    );
  }

  static void back(BuildContext context) {
    final overlay = AuthOverlayController.maybeOf(context);
    if (overlay != null) {
      overlay.onBack();
      return;
    }
    if (_hasGoRouter(context)) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
  }
}
