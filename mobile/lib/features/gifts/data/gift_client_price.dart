import '../../../core/network/api_exception.dart';

/// Sunucu ile katalog birim fiyatını doğrulamak için (canlifal PR #38).
const giftPriceMismatchUserMessage =
    'Fiyat güncellendi, lütfen tekrar deneyin.';

/// POST gövdesine eklenecek opsiyonel `clientPrice` (birim jeton).
Map<String, dynamic> giftClientPriceFields(int? unitPrice) {
  if (unitPrice == null || unitPrice <= 0) return const {};
  return {'clientPrice': unitPrice};
}

bool isGiftPriceMismatch(Object error) {
  if (error is! ApiException) return false;
  if (error.errorCode == 'PRICE_MISMATCH') return true;
  if (error.statusCode == 409) {
    final lower = error.message.toLowerCase();
    if (lower.contains('price') && lower.contains('mismatch')) return true;
    if (error.message.contains('Fiyat güncellendi')) return true;
  }
  return false;
}

String giftSendUserMessage(Object error) {
  if (isGiftPriceMismatch(error)) return giftPriceMismatchUserMessage;
  return ApiException.userMessage(error);
}
