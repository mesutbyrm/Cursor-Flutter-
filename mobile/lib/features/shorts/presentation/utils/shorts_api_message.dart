import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';

String shortsErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  final s = error.toString();
  if (s.startsWith('ApiException:')) {
    return s.replaceFirst('ApiException:', '').trim();
  }
  return 'Bir hata oluştu. Tekrar deneyin.';
}

void showShortsSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
