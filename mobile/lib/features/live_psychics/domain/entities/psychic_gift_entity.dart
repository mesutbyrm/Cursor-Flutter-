import 'package:equatable/equatable.dart';

/// Falcıya gelen hediye özeti — `GET /api/fortune-tellers/gifts?tellerId=`.
class PsychicGiftEntity extends Equatable {
  const PsychicGiftEntity({
    required this.senderId,
    required this.senderName,
    required this.giftCount,
    this.senderImage,
    this.totalJeton = 0,
  });

  final String senderId;
  final String senderName;
  final int giftCount;
  final String? senderImage;
  final int totalJeton;

  @override
  List<Object?> get props =>
      [senderId, senderName, giftCount, senderImage, totalJeton];
}
