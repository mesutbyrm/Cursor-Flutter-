/// Oturum içi ziyaret / yoğunluk metrikleri (yalnızca cihaz oturumu; sunucu raporu önceliklidir).
class GirLivePublisherSessionMetrics {
  const GirLivePublisherSessionMetrics({
    required this.roomKey,
    required this.startedAt,
    this.totalVisitEvents = 0,
    this.uniqueVisitorIds = const {},
    this.returnVisitorIds = const {},
    this.hourlyJoinBuckets = const {},
    this.lastActiveViewerCount = 0,
    this.peakActiveViewerCount = 0,
    this.pkCompleted = 0,
    this.pkWon = 0,
    this.pkLost = 0,
    this.pkDraw = 0,
    this.pkGiftJetonDuringPk = 0,
    this.recordedPkBattleIds = const {},
  });

  final String roomKey;
  final DateTime startedAt;
  final int totalVisitEvents;
  final Set<String> uniqueVisitorIds;
  final Set<String> returnVisitorIds;
  final Map<int, int> hourlyJoinBuckets;
  final int lastActiveViewerCount;
  final int peakActiveViewerCount;
  final int pkCompleted;
  final int pkWon;
  final int pkLost;
  final int pkDraw;
  final int pkGiftJetonDuringPk;
  final Set<String> recordedPkBattleIds;

  int get uniqueVisitorCount => uniqueVisitorIds.length;

  int get returnVisitorCount => returnVisitorIds.length;

  Duration get elapsed => DateTime.now().difference(startedAt);

  /// En yoğun saat dilimi (yerel saat); yeterli veri yoksa null.
  (int hour, int count)? get peakHourBucket {
    if (hourlyJoinBuckets.isEmpty) return null;
    var bestHour = -1;
    var best = 0;
    for (final e in hourlyJoinBuckets.entries) {
      if (e.value > best) {
        best = e.value;
        bestHour = e.key;
      }
    }
    if (bestHour < 0 || best < 2) return null;
    return (bestHour, best);
  }

  GirLivePublisherSessionMetrics copyWith({
    int? totalVisitEvents,
    Set<String>? uniqueVisitorIds,
    Set<String>? returnVisitorIds,
    Map<int, int>? hourlyJoinBuckets,
    int? lastActiveViewerCount,
    int? peakActiveViewerCount,
    int? pkCompleted,
    int? pkWon,
    int? pkLost,
    int? pkDraw,
    int? pkGiftJetonDuringPk,
    Set<String>? recordedPkBattleIds,
  }) {
    return GirLivePublisherSessionMetrics(
      roomKey: roomKey,
      startedAt: startedAt,
      totalVisitEvents: totalVisitEvents ?? this.totalVisitEvents,
      uniqueVisitorIds: uniqueVisitorIds ?? this.uniqueVisitorIds,
      returnVisitorIds: returnVisitorIds ?? this.returnVisitorIds,
      hourlyJoinBuckets: hourlyJoinBuckets ?? this.hourlyJoinBuckets,
      lastActiveViewerCount:
          lastActiveViewerCount ?? this.lastActiveViewerCount,
      peakActiveViewerCount:
          peakActiveViewerCount ?? this.peakActiveViewerCount,
      pkCompleted: pkCompleted ?? this.pkCompleted,
      pkWon: pkWon ?? this.pkWon,
      pkLost: pkLost ?? this.pkLost,
      pkDraw: pkDraw ?? this.pkDraw,
      pkGiftJetonDuringPk: pkGiftJetonDuringPk ?? this.pkGiftJetonDuringPk,
      recordedPkBattleIds: recordedPkBattleIds ?? this.recordedPkBattleIds,
    );
  }
}
