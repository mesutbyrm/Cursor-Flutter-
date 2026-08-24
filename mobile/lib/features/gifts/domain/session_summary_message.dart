import 'session_gift_summary.dart';

/// Oturum sonu özeti — sohbet sistem mesajı metinleri.
abstract final class SessionSummaryMessage {
  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds <= 0) return '';
    final totalSec = duration.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) return '${h} sa ${m} dk';
    if (m > 0) return '$m dk';
    return '$s sn';
  }

  static List<String> lines(
    SessionGiftSummary summary, {
    int? viewerCount,
    Duration? duration,
    String endedLabel = 'Oturum sona erdi',
  }) {
    final out = <String>[endedLabel];
    final parts = <String>[];
    if (viewerCount != null && viewerCount > 0) {
      parts.add('$viewerCount kişi girdi');
    }
    if (summary.totalGrossJeton > 0) {
      parts.add('${summary.totalGrossJeton} jeton hediye');
    }
    final dur = formatDuration(duration);
    if (dur.isNotEmpty) parts.add('süre $dur');
    if (parts.isNotEmpty) {
      out.add('Özet: ${parts.join(' · ')}');
    }
    if (summary.myNetJeton > 0) {
      out.add(summary.formatJetonWithTl(summary.myNetJeton));
    } else if (summary.isHostOrOwner && summary.totalGrossJeton > 0) {
      out.add('Toplam hediye: ${summary.formatJeton(summary.totalGrossJeton)}');
    }
    return out;
  }
}
