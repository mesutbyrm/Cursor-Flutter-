import 'dart:async';

import '../../../../core/network/api_exception.dart';

/// Sheet kapanış animasyonu + oda rebuild'i bittikten sonra isteği gönderir.
/// Aynı frame'de provider/WebView güncellemesi ANR yapar.
const kVoiceMusicSubmitDeferMs = 320;

/// Ağ + DJ state güncellemesini modal sheet kapanışından sonra erteler.
void deferVoiceMusicSubmit({
  required Future<String?> Function() submit,
  required void Function(String? error) onComplete,
}) {
  unawaited(
    (() async {
      await Future<void>.delayed(
        const Duration(milliseconds: kVoiceMusicSubmitDeferMs),
      );
      // Bir event-loop turu — sheet pop animasyonu + rebuild bitsin.
      await Future<void>.delayed(Duration.zero);
      try {
        final err = await submit();
        onComplete(err);
      } catch (e) {
        onComplete(ApiException.userMessage(e));
      }
    })(),
  );
}
