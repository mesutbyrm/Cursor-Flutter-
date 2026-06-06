import 'package:equatable/equatable.dart';

/// Sunucu PK durumu — web ve Flutter ortak sözleşme.
class PkBattleRemote extends Equatable {
  const PkBattleRemote({
    required this.id,
    required this.battleType,
    required this.status,
    required this.challengerScore,
    required this.opponentScore,
    required this.secondsLeft,
    required this.durationSeconds,
    required this.targetScore,
    this.voiceRoomId,
    this.opponentVoiceRoomId,
    this.liveStreamId,
    this.opponentLiveStreamId,
    this.challengerId,
    this.opponentId,
    this.winnerId,
    this.challenger,
    this.opponent,
    this.result,
    this.recentGifts = const [],
  });

  final String id;
  final String battleType;
  final String status;
  final int challengerScore;
  final int opponentScore;
  final int secondsLeft;
  final int durationSeconds;
  final int targetScore;
  final String? voiceRoomId;
  final String? opponentVoiceRoomId;
  final String? liveStreamId;
  final String? opponentLiveStreamId;
  final String? challengerId;
  final String? opponentId;
  final String? winnerId;
  final PkParticipantRemote? challenger;
  final PkParticipantRemote? opponent;
  final PkResultRemote? result;
  final List<PkGiftRemote> recentGifts;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended' || status == 'rejected';

  factory PkBattleRemote.fromJson(Map<String, dynamic> json) {
    final giftsRaw = json['recentGifts'];
    return PkBattleRemote(
      id: json['id']?.toString() ?? '',
      battleType: json['battleType']?.toString() ?? 'voice_room',
      status: json['status']?.toString() ?? 'pending',
      challengerScore: _int(json['challengerScore'] ?? json['leftScore']),
      opponentScore: _int(json['opponentScore'] ?? json['rightScore']),
      secondsLeft: _int(json['secondsLeft'], fallback: 300),
      durationSeconds: _int(json['durationSeconds'], fallback: 300),
      targetScore: _int(json['targetScore'], fallback: 150000),
      voiceRoomId: json['voiceRoomId']?.toString(),
      opponentVoiceRoomId: json['opponentVoiceRoomId']?.toString(),
      liveStreamId: json['liveStreamId']?.toString(),
      opponentLiveStreamId: json['opponentLiveStreamId']?.toString(),
      challengerId: json['challengerId']?.toString(),
      opponentId: json['opponentId']?.toString(),
      winnerId: json['winnerId']?.toString(),
      challenger: json['challenger'] is Map
          ? PkParticipantRemote.fromJson(
              Map<String, dynamic>.from(json['challenger'] as Map),
            )
          : null,
      opponent: json['opponent'] is Map
          ? PkParticipantRemote.fromJson(
              Map<String, dynamic>.from(json['opponent'] as Map),
            )
          : null,
      result: json['result'] is Map
          ? PkResultRemote.fromJson(
              Map<String, dynamic>.from(json['result'] as Map),
            )
          : null,
      recentGifts: giftsRaw is List
          ? giftsRaw
              .whereType<Map>()
              .map((e) => PkGiftRemote.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static int _int(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  @override
  List<Object?> get props => [id, status, challengerScore, opponentScore, secondsLeft];
}

class PkParticipantRemote extends Equatable {
  const PkParticipantRemote({
    required this.userId,
    this.roomId,
    this.streamId,
    this.score = 0,
    this.winStreak = 0,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? roomId;
  final String? streamId;
  final int score;
  final int winStreak;
  final String? displayName;
  final String? avatarUrl;

  factory PkParticipantRemote.fromJson(Map<String, dynamic> json) {
    return PkParticipantRemote(
      userId: json['userId']?.toString() ?? '',
      roomId: json['roomId']?.toString(),
      streamId: json['streamId']?.toString(),
      score: PkBattleRemote._int(json['score']),
      winStreak: PkBattleRemote._int(json['winStreak']),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  @override
  List<Object?> get props => [userId, score, winStreak];
}

class PkResultRemote extends Equatable {
  const PkResultRemote({
    this.winnerId,
    this.winnerSide,
    required this.challengerFinalScore,
    required this.opponentFinalScore,
    this.championBadge = true,
  });

  final String? winnerId;
  final String? winnerSide;
  final int challengerFinalScore;
  final int opponentFinalScore;
  final bool championBadge;

  factory PkResultRemote.fromJson(Map<String, dynamic> json) {
    return PkResultRemote(
      winnerId: json['winnerId']?.toString(),
      winnerSide: json['winnerSide']?.toString(),
      challengerFinalScore: PkBattleRemote._int(json['challengerFinalScore']),
      opponentFinalScore: PkBattleRemote._int(json['opponentFinalScore']),
      championBadge: json['championBadge'] != false,
    );
  }

  @override
  List<Object?> get props => [winnerId, winnerSide];
}

class PkGiftRemote extends Equatable {
  const PkGiftRemote({
    required this.id,
    required this.senderName,
    required this.side,
    required this.giftSlug,
    required this.points,
    this.quantity = 1,
    this.giftName,
  });

  final String id;
  final String senderName;
  final String side;
  final String giftSlug;
  final String? giftName;
  final int quantity;
  final int points;

  factory PkGiftRemote.fromJson(Map<String, dynamic> json) {
    return PkGiftRemote(
      id: json['id']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      side: json['side']?.toString() ?? 'challenger',
      giftSlug: json['giftSlug']?.toString() ?? '',
      giftName: json['giftName']?.toString(),
      quantity: PkBattleRemote._int(json['quantity'], fallback: 1),
      points: PkBattleRemote._int(json['points']),
    );
  }

  @override
  List<Object?> get props => [id, points, side];
}
