import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';
import '../ui/premium/premium_bottom_sheet.dart';

/// CDS modal bottom sheet — barrier, radius, klavye padding standart.
abstract final class CdsBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = true,
  }) {
    return showPremiumBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      child: child,
    );
  }

  /// Özel cam içerik (voice/live) — barrier + klavye padding; şeffaf zemin.
  static Future<T?> showTransparent<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    final barrier = context.colors.barrier;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: barrier,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: builder(ctx),
        );
      },
    );
  }
}
