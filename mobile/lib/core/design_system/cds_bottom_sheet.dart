import 'package:flutter/material.dart';

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
}
