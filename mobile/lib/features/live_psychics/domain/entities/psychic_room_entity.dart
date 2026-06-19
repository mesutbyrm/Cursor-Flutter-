import 'package:equatable/equatable.dart';

import 'psychic_session_status.dart';

/// `GET /api/room/{sessionId}` yanıtı.
class PsychicRoomEntity extends Equatable {
  const PsychicRoomEntity({
    required this.sessionId,
    required this.status,
    required this.maxMinutes,
    required this.timerStarted,
    this.roomId,
    this.timerStartedAt,
    this.peerId,
    this.tellerUserId,
    this.clientId,
    this.isClient = true,
    this.isTeller = false,
    this.elapsedSeconds = 0,
  });

  final String sessionId;
  final PsychicSessionStatus status;
  final int maxMinutes;
  final bool timerStarted;
  final int elapsedSeconds;
  final String? roomId;
  final DateTime? timerStartedAt;
  final String? peerId;
  final String? tellerUserId;
  final String? clientId;
  final bool isClient;
  final bool isTeller;

  int get remainingSeconds {
    if (!timerStarted || timerStartedAt == null) return maxMinutes * 60;
    final total = maxMinutes * 60;
    final elapsed = elapsedSeconds > 0
        ? elapsedSeconds
        : DateTime.now().difference(timerStartedAt!).inSeconds;
    return total - elapsed;
  }

  PsychicRoomEntity copyWith({
    String? sessionId,
    PsychicSessionStatus? status,
    int? maxMinutes,
    bool? timerStarted,
    String? roomId,
    DateTime? timerStartedAt,
    String? peerId,
    String? tellerUserId,
    String? clientId,
    bool? isClient,
    bool? isTeller,
    int? elapsedSeconds,
  }) {
    return PsychicRoomEntity(
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      maxMinutes: maxMinutes ?? this.maxMinutes,
      timerStarted: timerStarted ?? this.timerStarted,
      roomId: roomId ?? this.roomId,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      peerId: peerId ?? this.peerId,
      tellerUserId: tellerUserId ?? this.tellerUserId,
      clientId: clientId ?? this.clientId,
      isClient: isClient ?? this.isClient,
      isTeller: isTeller ?? this.isTeller,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        status,
        maxMinutes,
        timerStarted,
        roomId,
        timerStartedAt,
        peerId,
        tellerUserId,
        clientId,
        isClient,
        isTeller,
        elapsedSeconds,
      ];
}

/// Seans sohbet mesajı.
class PsychicChatMessage extends Equatable {
  const PsychicChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
    this.isMine = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [id, senderId, senderName, text, createdAt, isMine];
}
