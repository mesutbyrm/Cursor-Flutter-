import '../../../../core/util/json_util.dart';

class PaymentConfigEntity {
  const PaymentConfigEntity({
    required this.whatsappNumber,
    required this.paparaAddress,
    required this.bankIban,
    this.bankName,
    this.accountHolder,
  });

  factory PaymentConfigEntity.fromJson(Map<String, dynamic> json) {
    return PaymentConfigEntity(
      whatsappNumber:
          (pick(json, ['whatsappNumber', 'whatsapp']) ?? '').toString(),
      paparaAddress:
          (pick(json, ['paparaAddress', 'papara']) ?? '').toString(),
      bankIban: (pick(json, ['bankIban', 'iban']) ?? '').toString(),
      bankName: pick(json, ['bankName'])?.toString(),
      accountHolder: pick(json, ['accountHolder', 'holder'])?.toString(),
    );
  }

  final String whatsappNumber;
  final String paparaAddress;
  final String bankIban;
  final String? bankName;
  final String? accountHolder;
}
