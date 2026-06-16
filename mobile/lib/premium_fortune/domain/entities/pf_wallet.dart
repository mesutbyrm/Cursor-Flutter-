import 'package:equatable/equatable.dart';

enum PfTransactionType { purchase, spend, reward, coupon, refund }

class PfWalletTransaction extends Equatable {
  const PfWalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.referenceId,
  });

  final String id;
  final String userId;
  final PfTransactionType type;
  final int amount;
  final int balanceAfter;
  final String description;
  final DateTime createdAt;
  final String? referenceId;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        balanceAfter,
        description,
        createdAt,
        referenceId,
      ];
}

class PfCreditPackage extends Equatable {
  const PfCreditPackage({
    required this.id,
    required this.credits,
    required this.priceLabel,
    required this.priceCents,
    this.bonusCredits = 0,
    this.isPopular = false,
  });

  final String id;
  final int credits;
  final String priceLabel;
  final int priceCents;
  final int bonusCredits;
  final bool isPopular;

  int get totalCredits => credits + bonusCredits;

  @override
  List<Object?> get props => [id, credits, priceLabel, priceCents, bonusCredits, isPopular];
}
