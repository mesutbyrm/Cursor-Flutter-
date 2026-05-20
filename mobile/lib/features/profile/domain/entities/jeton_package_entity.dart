import 'package:equatable/equatable.dart';

/// canlifal.com `/api/jeton` yanıtından türetilen paket satırı.
class JetonPackageEntity extends Equatable {
  const JetonPackageEntity({
    required this.id,
    required this.title,
    required this.coins,
    this.priceTry,
    this.priceLabel,
    this.badge,
  });

  final String id;
  final String title;
  final int coins;
  final double? priceTry;
  final String? priceLabel;
  final String? badge;

  @override
  List<Object?> get props =>
      [id, title, coins, priceTry, priceLabel, badge];
}
