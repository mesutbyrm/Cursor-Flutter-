/// `GET /api/fortune-tellers/{tellerId}/reviews` — tek yorum kaydı.
class LiveTellerReviewEntity {
  const LiveTellerReviewEntity({
    required this.id,
    required this.tellerId,
    required this.sessionId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.reviewerName,
    this.reviewerUsername,
    this.reviewerImage,
    this.fortuneType,
  });

  final String id;
  final String tellerId;
  final String sessionId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? reviewerName;
  final String? reviewerUsername;
  final String? reviewerImage;
  final String? fortuneType;
}

/// Yorum listesi + özet istatistikler.
class LiveTellerReviewsBundle {
  const LiveTellerReviewsBundle({
    this.reviews = const [],
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  final List<LiveTellerReviewEntity> reviews;
  final double averageRating;
  final int totalReviews;
}

/// `GET /api/fortune-tellers/awards` — falcı ödülü.
class LiveTellerAwardEntity {
  const LiveTellerAwardEntity({
    required this.id,
    required this.tellerId,
    required this.awardType,
    required this.title,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  final String id;
  final String tellerId;
  final String awardType;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
}

/// `GET /api/fortune-tellers/gifts` — hediye özeti.
class LiveTellerGiftSummaryEntity {
  const LiveTellerGiftSummaryEntity({
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
}

/// `POST /api/fortune-tellers/apply` yanıtı.
class FortuneTellerApplyResult {
  const FortuneTellerApplyResult({
    required this.success,
    this.tellerId,
    this.applicationStatus,
    this.message,
  });

  final bool success;
  final String? tellerId;
  final String? applicationStatus;
  final String? message;
}

/// WebRTC sinyal kaydı — `POST/GET /api/room/signal`.
class LiveFortuneRoomSignalEntity {
  const LiveFortuneRoomSignalEntity({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.receiverId,
    required this.signalType,
    required this.signalData,
    this.processed = false,
    this.createdAt,
  });

  final String id;
  final String sessionId;
  final String senderId;
  final String receiverId;
  final String signalType;
  final Map<String, dynamic> signalData;
  final bool processed;
  final DateTime? createdAt;
}
