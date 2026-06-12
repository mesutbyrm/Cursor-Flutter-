import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/premium_2026/premium_motion.dart';

/// Android varsayılan geçişleri modal barrier/scrim bırakabiliyor — barrier yok.
class NoBarrierPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoBarrierPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Premium sayfa geçişleri — iOS Cupertino + TikTok fade-slide.
abstract final class AppPageTransitions {
  /// Auth splash/login — geçiş animasyonu gri scrim bırakabiliyor (Android).
  static NoTransitionPage<T> none<T>({
    required LocalKey? key,
    required Widget child,
  }) {
    return NoTransitionPage<T>(
      key: key,
      child: child,
    );
  }

  static CustomTransitionPage<T> fadeSlide<T>({
    required LocalKey? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  static CustomTransitionPage<T> sharedAxis<T>({
    required LocalKey? key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Tam ekran modal — Threads / Revolut tarzı.
  static CustomTransitionPage<T> cupertinoSheet<T>({
    required LocalKey? key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: PremiumMotion.sheet,
      reverseTransitionDuration: PremiumMotion.sheet,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      },
    );
  }
}
