import '../content/currency_usage_info.dart';
import '../../features/profile/domain/entities/payment_config_entity.dart';

/// canlifal.com ödeme ayarları yüklenmezse — site ile aynı bilgiler.
abstract final class PaymentDefaults {
  static const whatsapp = '05327170173';
  static const papara = '1555517633';
  static const accountHolder = 'Mesut bayram';
  static const bankName = 'Garanti Bankası';
  static const iban = 'TR94 0006 2000 0010 0006 8126 92';

  static const PaymentConfigEntity config = PaymentConfigEntity(
    whatsappNumber: whatsapp,
    paparaAddress: papara,
    bankIban: iban,
    bankName: bankName,
    bankAccountHolder: accountHolder,
    cfcRate: CurrencyUsageInfo.cfcTlPerCoin,
    minCfcAmount: 10,
  );

  static PaymentConfigEntity merge(PaymentConfigEntity? remote) {
    if (remote == null) return config;
    return PaymentConfigEntity(
      whatsappNumber: _pick(remote.whatsappNumber, whatsapp),
      paparaAddress: _pick(remote.paparaAddress, papara),
      bankIban: _pick(remote.bankIban, iban),
      bankName: _pick(remote.bankName ?? '', bankName),
      bankAccountHolder: _pick(remote.bankAccountHolder, accountHolder),
      cfcRate: _effectiveCfcRate(remote.cfcRate),
      minCfcAmount: remote.minCfcAmount > 0 ? remote.minCfcAmount : 10,
    );
  }

  static String _pick(String value, String fallback) {
    final t = value.trim();
    return t.isEmpty ? fallback : t;
  }

  /// Site 1 TL/CFC döndürse bile güncel tarife: 100 CFC = 25 TL.
  static double _effectiveCfcRate(double remoteRate) {
    if (remoteRate <= 0) return CurrencyUsageInfo.cfcTlPerCoin;
    if (remoteRate >= 1) return CurrencyUsageInfo.cfcTlPerCoin;
    return remoteRate;
  }
}
