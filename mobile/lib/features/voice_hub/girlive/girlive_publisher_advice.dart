import 'girlive_publisher_session_metrics.dart';

/// Veriye dayalı, garanti vaat etmeyen yayıncı önerileri.
abstract final class GirLivePublisherAdvice {
  static List<String> build({
    required GirLivePublisherSessionMetrics metrics,
    required int grossGiftJeton,
    required int giftCount,
    required bool pkGiftsDominant,
  }) {
    final tips = <String>[];

    final peak = metrics.peakHourBucket;
    if (peak != null) {
      final h = peak.$1;
      final next = (h + 1) % 24;
      tips.add(
        'Son oturumda en yoğun saat diliminiz '
        '${_fmtHour(h)}–${_fmtHour(next)} civarıydı. '
        'Önümüzdeki yayınlarda bu aralığı deneyebilirsiniz.',
      );
    }

    if (metrics.elapsed.inMinutes >= 120 && metrics.totalVisitEvents >= 10) {
      tips.add(
        'Uzun süredir yayındasınız. Kısa bir mola veya '
        'izleyicilere mini etkinlik duyurusu ilgi canlı tutabilir.',
      );
    }

    if (metrics.pkCompleted >= 3) {
      final rate = metrics.pkWon / metrics.pkCompleted;
      if (rate >= 0.5) {
        tips.add(
          'Son oturumda tamamlanan ${metrics.pkCompleted} PK\'nın '
          '${metrics.pkWon}\'ini kazandınız. Bir sonraki PK öncesinde '
          'karşılaşmanın başladığını duyurabilirsiniz.',
        );
      }
    }

    if (grossGiftJeton >= 500 && giftCount >= 3 && pkGiftsDominant) {
      tips.add(
        'Hediye gönderimlerinin önemli kısmı PK sırasında gerçekleşti. '
        'PK öncesi kısa bir destek çağrısı yapmayı düşünebilirsiniz.',
      );
    }

    if (metrics.returnVisitorCount >= 3 && metrics.uniqueVisitorCount >= 5) {
      tips.add(
        'Düzenli dönen ${metrics.returnVisitorCount} ziyaretçiniz var. '
        'Onlara teşekkür etmek topluluğu güçlendirebilir.',
      );
    }

    return tips.take(4).toList();
  }

  static String? liveStatusLine({
    required GirLivePublisherSessionMetrics metrics,
    required String patronOrName,
  }) {
    if (metrics.totalVisitEvents < 1 && metrics.elapsed.inMinutes < 5) {
      return null;
    }
    final d = metrics.elapsed;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final dur = h > 0 ? '$h saat $m dakika' : '$m dakika';
    final visits = metrics.totalVisitEvents;
    final peak = metrics.peakHourBucket;
    final peakTxt = peak != null
        ? ' En yoğun saat diliminiz ${_fmtHour(peak.$1)}–${_fmtHour((peak.$1 + 1) % 24)} oldu.'
        : '';
    return '📊 $patronOrName, bu yayın $dur süredir devam ediyor. '
        'Şu ana kadar $visits ziyaret gerçekleşti.$peakTxt';
  }

  static String _fmtHour(int h) =>
      '${h.toString().padLeft(2, '0')}.00';
}
