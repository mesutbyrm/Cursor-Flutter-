import 'package:equatable/equatable.dart';

import 'psychic_entity.dart';
import 'psychic_room_entity.dart';

/// Aktif canlı fal oturumu.
class PsychicSessionEntity extends Equatable {
  const PsychicSessionEntity({
    required this.sessionId,
    required this.psychic,
    required this.durationMinutes,
    required this.totalJeton,
    this.tellerUserId,
    this.clientId,
    this.isClient = true,
    this.trtcRoomIdOverride,
    this.fortuneType = 'general',
  });

  final String sessionId;
  final PsychicEntity psychic;
  final int durationMinutes;
  final int totalJeton;
  final String? tellerUserId;
  final String? clientId;
  final bool isClient;
  final String? trtcRoomIdOverride;
  final String fortuneType;

  String get trtcRoomId =>
      (trtcRoomIdOverride?.trim().isNotEmpty == true)
          ? trtcRoomIdOverride!.trim()
          : sessionId;

  String get anchorUserId {
    final fromSession = tellerUserId?.trim();
    if (fromSession != null && fromSession.isNotEmpty) return fromSession;
    return psychic.trtcUserId;
  }

  String remotePeerIdFor({PsychicRoomEntity? room}) {
    final peer = room?.peerId?.trim();
    if (peer != null && peer.isNotEmpty) return peer;
    if (isClient) {
      final anchor = room?.tellerUserId?.trim();
      if (anchor != null && anchor.isNotEmpty) return anchor;
      return anchorUserId;
    }
    final client = room?.clientId?.trim() ?? clientId?.trim();
    if (client != null && client.isNotEmpty) return client;
    return '';
  }

  PsychicSessionEntity copyWith({
    String? sessionId,
    PsychicEntity? psychic,
    int? durationMinutes,
    int? totalJeton,
    String? tellerUserId,
    String? clientId,
    bool? isClient,
    String? trtcRoomIdOverride,
    String? fortuneType,
  }) {
    return PsychicSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      psychic: psychic ?? this.psychic,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalJeton: totalJeton ?? this.totalJeton,
      tellerUserId: tellerUserId ?? this.tellerUserId,
      clientId: clientId ?? this.clientId,
      isClient: isClient ?? this.isClient,
      trtcRoomIdOverride: trtcRoomIdOverride ?? this.trtcRoomIdOverride,
      fortuneType: fortuneType ?? this.fortuneType,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        psychic,
        durationMinutes,
        totalJeton,
        tellerUserId,
        clientId,
        isClient,
        trtcRoomIdOverride,
        fortuneType,
      ];
}
