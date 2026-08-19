import 'dart:async';

import '../../../../core/network/api_exception.dart';

/// Ağ + DJ state güncellemesini bir sonraki microtask'e erteler.
/// Sheet kapanışı / oda rebuild'i ile çakışınca UI donmasını önler.
void deferVoiceMusicSubmit({
  required Future<String?> Function() submit,
  required void Function(String? error) onComplete,
}) {
  unawaited(
    Future<void>.microtask(() async {
      try {
        final err = await submit();
        onComplete(err);
      } catch (e) {
        onComplete(ApiException.userMessage(e));
      }
    }),
  );
}
