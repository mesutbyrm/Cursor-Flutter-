import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import 'error_handler.dart';

/// Standart API hata snackbar — 429 için özel mesaj.
abstract final class ApiSnackBar {
  static const rateLimitMessage =
      'Çok fazla istek gönderildi. Lütfen biraz bekleyip tekrar deneyin.';

  static void show(BuildContext context, Object error, {String? fallback}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(messageFor(error, fallback: fallback)),
        behavior: SnackBarBehavior.floating,
        duration: isRateLimited(error)
            ? const Duration(seconds: 5)
            : const Duration(seconds: 4),
      ),
    );
  }

  static String messageFor(Object error, {String? fallback}) {
    if (isRateLimited(error)) return rateLimitMessage;
    return ErrorHandler.message(error, fallback: fallback ?? 'Bir hata oluştu');
  }

  static bool isRateLimited(Object error) {
    if (error is ApiException && error.statusCode == 429) return true;
    final raw = error.toString();
    return raw.contains('429');
  }
}
