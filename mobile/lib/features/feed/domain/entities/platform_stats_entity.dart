import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

/// Ana sayfa canlı istatistik kartları.
class PlatformStatsEntity extends Equatable {
  const PlatformStatsEntity({
    required this.onlineUsers,
    required this.inGames,
    required this.inSocial,
    required this.onLive,
    required this.inVoiceChat,
    required this.fortuneActive,
    required this.browsing,
    required this.todayLogins,
    this.recentLogins = const [],
  });

  final int onlineUsers;
  final int inGames;
  final int inSocial;
  final int onLive;
  final int inVoiceChat;
  final int fortuneActive;
  final int browsing;
  final int todayLogins;
  final List<RecentLoginEntity> recentLogins;

  @override
  List<Object?> get props => [
        onlineUsers,
        inGames,
        inSocial,
        onLive,
        inVoiceChat,
        fortuneActive,
        browsing,
        todayLogins,
        recentLogins,
      ];
}

class RecentLoginEntity extends Equatable {
  const RecentLoginEntity({
    required this.user,
    required this.timeLabel,
    required this.activityLabel,
    this.activityEmoji = '✋',
    this.verified = false,
  });

  final UserEntity user;
  final String timeLabel;
  final String activityLabel;
  final String activityEmoji;
  final bool verified;

  @override
  List<Object?> get props =>
      [user, timeLabel, activityLabel, activityEmoji, verified];
}
