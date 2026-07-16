import 'package:equatable/equatable.dart';

import '../../../../core/util/json_util.dart';
import 'trtc_credentials.dart';

/// `POST /api/live/join-room` yanıtı.
class LiveJoinRoomResult extends Equatable {
  const LiveJoinRoomResult({
    required this.room,
    required this.trtc,
    this.user,
    this.participants = const [],
    this.seats = const [],
    this.giftRanking = const [],
    this.pkStatus,
  });

  final LiveJoinRoomInfo room;
  final TrtcCredentials trtc;
  final LiveJoinUserInfo? user;
  final List<LiveJoinParticipant> participants;
  final List<LiveJoinSeat> seats;
  final List<LiveGiftRankingEntry> giftRanking;
  final LivePkStatus? pkStatus;

  factory LiveJoinRoomResult.fromJson(Map<String, dynamic> json) {
    final roomMap = asJsonMap(json['room']) ?? {};
    final trtcMap = asJsonMap(json['trtc']) ?? {};
    final userMap = asJsonMap(json['user']);
    final pkMap = asJsonMap(json['pkStatus'] ?? json['pk']);

    return LiveJoinRoomResult(
      room: LiveJoinRoomInfo.fromJson(roomMap),
      trtc: TrtcCredentials.fromJson(trtcMap),
      user: userMap != null ? LiveJoinUserInfo.fromJson(userMap) : null,
      participants: _parseList(json['participants'], LiveJoinParticipant.fromJson),
      seats: _parseList(json['seats'], LiveJoinSeat.fromJson),
      giftRanking: _parseList(json['giftRanking'], LiveGiftRankingEntry.fromJson),
      pkStatus: pkMap != null ? LivePkStatus.fromJson(pkMap) : null,
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw
        .map((e) => asJsonMap(e))
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  @override
  List<Object?> get props =>
      [room, trtc, user, participants, seats, giftRanking, pkStatus];
}

class LiveJoinRoomInfo extends Equatable {
  const LiveJoinRoomInfo({
    required this.id,
    this.title,
    this.hostId,
    this.hostName,
    this.hostImage,
    this.status,
    this.viewerCount = 0,
    this.backgroundImage,
  });

  final String id;
  final String? title;
  final String? hostId;
  final String? hostName;
  final String? hostImage;
  final String? status;
  final int viewerCount;
  final String? backgroundImage;

  factory LiveJoinRoomInfo.fromJson(Map<String, dynamic> json) {
    return LiveJoinRoomInfo(
      id: json['id']?.toString() ?? json['roomId']?.toString() ?? '',
      title: json['title']?.toString(),
      hostId: json['hostId']?.toString(),
      hostName: json['hostName']?.toString(),
      hostImage: json['hostImage']?.toString(),
      status: json['status']?.toString(),
      viewerCount: (json['viewerCount'] as num?)?.toInt() ?? 0,
      backgroundImage: json['backgroundImage']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, hostId, hostName, hostImage, status, viewerCount, backgroundImage];
}

class LiveJoinUserInfo extends Equatable {
  const LiveJoinUserInfo({
    required this.id,
    this.name,
    this.image,
    this.isHost = false,
    this.role,
    this.seatIndex,
  });

  final String id;
  final String? name;
  final String? image;
  final bool isHost;
  final String? role;
  final int? seatIndex;

  factory LiveJoinUserInfo.fromJson(Map<String, dynamic> json) {
    return LiveJoinUserInfo(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['userName']?.toString(),
      image: json['image']?.toString() ?? json['userImage']?.toString(),
      isHost: json['isHost'] == true,
      role: json['role']?.toString(),
      seatIndex: (json['seatIndex'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [id, name, image, isHost, role, seatIndex];
}

class LiveJoinParticipant extends Equatable {
  const LiveJoinParticipant({
    required this.userId,
    this.userName,
    this.userImage,
    this.seatIndex,
    this.role,
  });

  final String userId;
  final String? userName;
  final String? userImage;
  final int? seatIndex;
  final String? role;

  factory LiveJoinParticipant.fromJson(Map<String, dynamic> json) {
    return LiveJoinParticipant(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      seatIndex: (json['seatIndex'] as num?)?.toInt(),
      role: json['role']?.toString(),
    );
  }

  @override
  List<Object?> get props => [userId, userName, userImage, seatIndex, role];
}

class LiveJoinSeat extends Equatable {
  const LiveJoinSeat({
    required this.seatIndex,
    this.userId,
    this.userName,
    this.userImage,
    this.isMicOn = false,
  });

  final int seatIndex;
  final String? userId;
  final String? userName;
  final String? userImage;
  final bool isMicOn;

  factory LiveJoinSeat.fromJson(Map<String, dynamic> json) {
    return LiveJoinSeat(
      seatIndex: (json['seatIndex'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      isMicOn: json['isMicOn'] == true,
    );
  }

  @override
  List<Object?> get props => [seatIndex, userId, userName, userImage, isMicOn];
}

class LiveGiftRankingEntry extends Equatable {
  const LiveGiftRankingEntry({
    required this.userId,
    this.userName,
    this.userImage,
    this.totalAmount = 0,
  });

  final String userId;
  final String? userName;
  final String? userImage;
  final int totalAmount;

  factory LiveGiftRankingEntry.fromJson(Map<String, dynamic> json) {
    return LiveGiftRankingEntry(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [userId, userName, userImage, totalAmount];
}

class LivePkStatus extends Equatable {
  const LivePkStatus({
    this.status,
    this.opponentRoomId,
    this.opponentHostId,
    this.score,
  });

  final String? status;
  final String? opponentRoomId;
  final String? opponentHostId;
  final int? score;

  factory LivePkStatus.fromJson(Map<String, dynamic> json) {
    return LivePkStatus(
      status: json['status']?.toString(),
      opponentRoomId: json['opponentRoomId']?.toString(),
      opponentHostId: json['opponentHostId']?.toString(),
      score: (json['score'] as num?)?.toInt(),
    );
  }

  bool get isActive {
    final s = status?.toLowerCase() ?? '';
    return s == 'active' || s == 'started' || s == 'live';
  }

  @override
  List<Object?> get props => [status, opponentRoomId, opponentHostId, score];
}

class LiveHeartbeatResult extends Equatable {
  const LiveHeartbeatResult({
    this.onlineCount = 0,
    this.staleRemoved = 0,
    this.serverTime,
  });

  final int onlineCount;
  final int staleRemoved;
  final DateTime? serverTime;

  factory LiveHeartbeatResult.fromJson(Map<String, dynamic> json) {
    final rawTime = json['serverTime']?.toString();
    return LiveHeartbeatResult(
      onlineCount: (json['onlineCount'] as num?)?.toInt() ?? 0,
      staleRemoved: (json['staleRemoved'] as num?)?.toInt() ?? 0,
      serverTime: rawTime != null ? DateTime.tryParse(rawTime) : null,
    );
  }

  @override
  List<Object?> get props => [onlineCount, staleRemoved, serverTime];
}
