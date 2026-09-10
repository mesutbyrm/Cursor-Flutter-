import 'package:equatable/equatable.dart';

import '../../../live/domain/pk/pk_status_helper.dart';

/// Sunucu PK durumu — web ve Flutter ortak sözleşme.
class PkBattleRemote extends Equatable {
  const PkBattleRemote({
    required this.id,
    this.inviteId,
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
    this.targetUserId,
    this.guestUserId,
    this.winnerId,
    this.challenger,
    this.opponent,
    this.result,
    this.recentGifts = const [],
    this.endsAt,
    this.startedAt,
  });

  final String id;
  final String? inviteId;
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
  final String? targetUserId;
  final String? guestUserId;
  final String? winnerId;
  final PkParticipantRemote? challenger;
  final PkParticipantRemote? opponent;
  final PkResultRemote? result;
  final List<PkGiftRemote> recentGifts;
  final DateTime? endsAt;
  final DateTime? startedAt;

  /// Sunucu `endsAt` / `startedAt` varsa öncelikli geri sayım.
  int resolvedSecondsLeft({DateTime? now}) {
    final t = (now ?? DateTime.now()).toUtc();
    if (endsAt != null) {
      return endsAt!.toUtc().difference(t).inSeconds.clamp(0, 86400);
    }
    if (startedAt != null && durationSeconds > 0) {
      final elapsed = t.difference(startedAt!.toUtc()).inSeconds;
      return (durationSeconds - elapsed).clamp(0, durationSeconds);
    }
    return secondsLeft.clamp(0, 86400);
  }

  bool get isPending => isPkInvitePendingStatus(status);
  bool get isActive => isLivePkActiveStatus(status);
  bool get isEnded =>
      status == 'ended' ||
      status == 'rejected' ||
      status == 'cancelled' ||
      status == 'completed' ||
      status == 'canceled';

  /// API yanıtında `inviteId` ayrı gelebilir — respond path için.
  String get effectiveId {
    final inv = inviteId?.trim() ?? '';
    if (inv.isNotEmpty) return inv;
    return id.trim();
  }

  factory PkBattleRemote.fromJson(Map<String, dynamic> json) {
    final giftsRaw = json['recentGifts'];
    final invite = json['inviteId']?.toString().trim();
    // API dokümanı §8: yanıtta `pkBattleId` birincil kimlik olabilir.
    final rawId = (json['id'] ??
            json['pkBattleId'] ??
            json['battleId'] ??
            json['inviteId'])
        ?.toString()
        .trim() ??
        '';
    final id = rawId.isNotEmpty ? rawId : (invite ?? '');
    var status = json['status']?.toString() ?? 'pending';
    // Sunucu accept sonrası "accepted" dönebilir — savaş aktif sayılır.
    if (status == 'accepted' || status == 'accepted_invite') {
      status = 'active';
    }
    final endsAt = _parseDate(json['endsAt'] ?? json['endAt']);
    final startedAt = _parseDate(
      json['startedAt'] ?? json['startAt'] ?? json['started_at'],
    );
    var secondsLeft = _int(json['secondsLeft'], fallback: 300);
    if (endsAt != null) {
      final left = endsAt.toUtc().difference(DateTime.now().toUtc()).inSeconds;
      if (left >= 0) secondsLeft = left;
    } else if (startedAt != null) {
      final duration = _int(json['durationSeconds'] ?? json['duration'], fallback: 180);
      final elapsed =
          DateTime.now().toUtc().difference(startedAt.toUtc()).inSeconds;
      secondsLeft = (duration - elapsed).clamp(0, duration);
    }
    return PkBattleRemote(
      id: id,
      inviteId: invite?.isNotEmpty == true ? invite : null,
      battleType: json['battleType']?.toString() ?? 'voice_room',
      status: status,
      challengerScore: _int(json['challengerScore'] ?? json['leftScore']),
      opponentScore: _int(json['opponentScore'] ?? json['rightScore']),
      secondsLeft: secondsLeft,
      durationSeconds: _int(
        json['durationSeconds'] ?? json['duration'],
        fallback: 180,
      ),
      targetScore: _int(json['targetScore'], fallback: 150000),
      voiceRoomId: (json['voiceRoomId'] ??
              json['challengerRoomId'] ??
              json['roomId'])
          ?.toString(),
      opponentVoiceRoomId: (json['opponentVoiceRoomId'] ??
              json['targetRoomId'] ??
              json['opponentRoomId'] ??
              json['guestRoomId'])
          ?.toString(),
      liveStreamId: json['liveStreamId']?.toString(),
      opponentLiveStreamId: json['opponentLiveStreamId']?.toString(),
      challengerId: (json['challengerId'] ?? json['hostUserId'])?.toString(),
      opponentId: (json['opponentId'] ?? json['opponentUserId'])?.toString(),
      targetUserId: json['targetUserId']?.toString(),
      guestUserId: json['guestUserId']?.toString(),
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
      endsAt: endsAt,
      startedAt: startedAt,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
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
