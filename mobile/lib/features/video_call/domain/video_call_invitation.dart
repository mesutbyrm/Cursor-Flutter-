import 'package:equatable/equatable.dart';

/// Gelen görüntülü çağrı daveti — canlı fal / TRTC oturumları için genel model.
class VideoCallInvitation extends Equatable {
  const VideoCallInvitation({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatarUrl,
    this.category,
    this.durationMinutes = 0,
    this.pricePerMinute,
    this.totalJeton = 0,
    this.sessionId,
    this.receivedAt,
  });

  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final String? category;
  final int durationMinutes;
  final double? pricePerMinute;
  final int totalJeton;
  final String? sessionId;
  final DateTime? receivedAt;

  String get displayCategory => category?.trim().isNotEmpty == true
      ? category!.trim()
      : 'Görüntülü görüşme';

  @override
  List<Object?> get props => [callId, callerId, callerName, sessionId];

  VideoCallInvitation copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatarUrl,
    String? category,
    int? durationMinutes,
    double? pricePerMinute,
    int? totalJeton,
    String? sessionId,
    DateTime? receivedAt,
  }) {
    return VideoCallInvitation(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      totalJeton: totalJeton ?? this.totalJeton,
      sessionId: sessionId ?? this.sessionId,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

enum VideoCallResponse { accept, reject, busy, timeout, missed }
