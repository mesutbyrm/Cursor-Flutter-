import 'package:flutter/material.dart';

import '../ui/premium/premium_empty_hint.dart';
import '../widgets/app_error_view.dart';
import 'cds_typography.dart';

/// CDS yükleme / boş / hata durumları.
abstract final class CdsLoading {
  static Widget centered({String? label}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label),
          ],
        ],
      ),
    );
  }
}

abstract final class CdsEmpty {
  static Widget hint({
    required String message,
    VoidCallback? onRetry,
  }) {
    return PremiumEmptyHint(message: message, onRetry: onRetry);
  }
}

abstract final class CdsError {
  static Widget view({
    required BuildContext context,
    required Object error,
    VoidCallback? onRetry,
  }) {
    return AppErrorView(
      message: error.toString(),
      onRetry: onRetry,
    );
  }

  static Widget inline(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: CdsTypography.body(context),
        textAlign: TextAlign.center,
      ),
    );
  }
}
