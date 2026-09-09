import '../../../gifts/presentation/sync/gift_hourly_reset.dart';
import '../providers/voice_room_ranking_provider.dart';

/// Saatlik / günlük sıralama penceresi — Europe/Istanbul yerel saat (istemci).
String voiceRoomRankingResetLabel(VoiceRoomRankingPeriod period, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  return switch (period) {
    VoiceRoomRankingPeriod.hourly => _hourlyLabel(clock),
    VoiceRoomRankingPeriod.daily => _dailyLabel(clock),
  };
}

String _hourlyLabel(DateTime now) {
  final remaining = GiftHourlyReset.delayUntilNextHour(now);
  final mins = remaining.inMinutes.clamp(0, 59);
  return 'Saatlik sıfırlama · ${mins} dk';
}

String _dailyLabel(DateTime now) {
  final next = DateTime(now.year, now.month, now.day + 1);
  final remaining = next.difference(now);
  final hours = remaining.inHours;
  final mins = remaining.inMinutes % 60;
  if (hours > 0) {
    return 'Günlük sıfırlama · ${hours}s ${mins}dk';
  }
  return 'Günlük sıfırlama · ${mins} dk';
}
