import '../../../../core/util/json_util.dart';

/// `GET /api/payment/config` — CFC yükleme kanalları.
class PaymentConfigEntity {
  const PaymentConfigEntity({
    required this.whatsappNumber,
    required this.paparaAddress,
    required this.bankIban,
    this.bankName,
    this.bankAccountHolder = '',
    this.cfcRate = 1,
    this.minCfcAmount = 10,
  });

  factory PaymentConfigEntity.fromJson(Map<String, dynamic> json) {
    return PaymentConfigEntity(
      whatsappNumber:
          (pick(json, ['whatsappNumber', 'whatsapp']) ?? '').toString(),
      paparaAddress:
          (pick(json, ['paparaAddress', 'papara']) ?? '').toString(),
      bankIban: (pick(json, ['bankIban', 'iban']) ?? '').toString(),
      bankName: pick(json, ['bankName'])?.toString(),
      bankAccountHolder: (pick(json, [
            'bankAccountHolder',
            'bankAccountHolderName',
            'accountHolder',
            'holder',
            'recipient',
            'alıcı',
          ]) ??
          '')
          .toString(),
      cfcRate: (pick(json, [
            'cfcRate',
            'cfc_rate',
            'cfcTlRate',
            'rate',
          ]) as num?)
              ?.toDouble() ??
          1,
      minCfcAmount: () {
        final m = asInt(pick(json, [
          'minCfcAmount',
          'min_cfc_amount',
          'minCfc',
          'minAmount',
        ]));
        return m > 0 ? m : 10;
      }(),
    );
  }

  final String whatsappNumber;
  final String paparaAddress;
  final String bankIban;
  final String? bankName;
  final String bankAccountHolder;
  final double cfcRate;
  final int minCfcAmount;
}
