import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/exit_confirm_dialog.dart';
import 'app_back_policy.dart';

/// Düz (üst düzey) rota sayfalarını sarar: yığında önceki sayfa YOKSA (sayfaya
/// `context.go()` ile gelinmiş) geri tuşu uygulamayı kapatmak yerine mantıklı
/// bir üst sayfaya gider; ana sayfada çıkış onayı gösterir.
///
/// Yığında önceki sayfa varsa hiçbir şeye karışmaz (normal pop). Kendi
/// PopScope'unu yöneten sayfalar [AppBackPolicy.selfHandlesBack] ile dışarıda
/// bırakılır.
class AppBackScope extends StatelessWidget {
  const AppBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return child;
    final location = _location(router);
    if (AppBackPolicy.selfHandlesBack(location)) return child;

    return PopScope(
      // Önceki sayfa varsa normal pop; yoksa aşağıdaki geri dönüşü biz yönetiriz.
      canPop: router.canPop(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final target = AppBackPolicy.fallbackFor(location);
        if (target == null) {
          await handleShellBackPress(context);
        } else {
          router.go(target);
        }
      },
      child: child,
    );
  }

  static String _location(GoRouter router) {
    try {
      return router.routerDelegate.currentConfiguration.uri.toString();
    } catch (_) {
      return '';
    }
  }
}
