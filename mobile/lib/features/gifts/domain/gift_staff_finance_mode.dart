/// Admin / kurucu hediye gönderiminde jeton finans modu.
enum GiftStaffFinanceMode {
  /// Alıcıya jeton düşmez; animasyon ve bildirim devam eder.
  staff,
  /// Normal ekonomi — alıcı/yayıncı kredilenir (bakiye kuralları sunucuda).
  real,
}

extension GiftStaffFinanceModeJson on GiftStaffFinanceMode {
  /// Üretim `POST` hediye gövdesi — `financeMode`: `staff` | `real`.
  Map<String, dynamic> toRequestFields() => {'financeMode': name};
}
