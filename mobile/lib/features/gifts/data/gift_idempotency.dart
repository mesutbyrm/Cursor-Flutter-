import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Parasal hediye POST'ları için çift işlem koruması (resmî entegrasyon §13.3).
String newGiftIdempotencyKey() => const Uuid().v4();

/// Abacus `gifts_coins_wallet_api.md` — `Idempotency-Key` / `X-Idempotency-Key` başlığı.
Options giftIdempotentPostOptions([String? key]) {
  final id = (key != null && key.isNotEmpty) ? key : newGiftIdempotencyKey();
  return Options(
    headers: {
      'Idempotency-Key': id,
      'X-Idempotency-Key': id,
    },
  );
}
