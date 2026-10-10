/// Sunucu `GET …/girlive/publisher-assistant` yanıtı (canlifal deploy sonrası).
class GirLivePublisherAssistantReport {
  const GirLivePublisherAssistantReport({
    this.sessionId,
    this.startedAt,
    this.endedAt,
    this.totalVisits,
    this.uniqueVisitors,
    this.returnVisitors,
    this.avgDwellSeconds,
    this.peakHourLocal,
    this.grossGiftJeton,
    this.netOwnerJeton,
    this.giftCount,
    this.topGifts = const [],
    this.topGifters = const [],
    this.pkCompleted,
    this.pkWon,
    this.pkLost,
    this.pkDraw,
    this.tips = const [],
    this.comparePrevious,
  });

  final String? sessionId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? totalVisits;
  final int? uniqueVisitors;
  final int? returnVisitors;
  final int? avgDwellSeconds;
  final int? peakHourLocal;
  final int? grossGiftJeton;
  final int? netOwnerJeton;
  final int? giftCount;
  final List<GirLiveTopGiftRow> topGifts;
  final List<GirLiveTopGifterRow> topGifters;
  final int? pkCompleted;
  final int? pkWon;
  final int? pkLost;
  final int? pkDraw;
  final List<String> tips;
  final GirLivePublisherCompare? comparePrevious;

  factory GirLivePublisherAssistantReport.fromJson(Map<String, dynamic> json) {
    DateTime? dt(dynamic v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    List<T> mapList<T>(
      dynamic raw,
      T Function(Map<String, dynamic> m) fn,
    ) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => fn(Map<String, dynamic>.from(e)))
          .toList();
    }

    GirLivePublisherCompare? cmp;
    final c = json['comparePrevious'];
    if (c is Map) {
      cmp = GirLivePublisherCompare.fromJson(Map<String, dynamic>.from(c));
    }

    return GirLivePublisherAssistantReport(
      sessionId: json['sessionId']?.toString(),
      startedAt: dt(json['startedAt']),
      endedAt: dt(json['endedAt']),
      totalVisits: _int(json['totalVisits']),
      uniqueVisitors: _int(json['uniqueVisitors']),
      returnVisitors: _int(json['returnVisitors']),
      avgDwellSeconds: _int(json['avgDwellSeconds']),
      peakHourLocal: _int(json['peakHourLocal']),
      grossGiftJeton: _int(json['grossGiftJeton']),
      netOwnerJeton: _int(json['netOwnerJeton']),
      giftCount: _int(json['giftCount']),
      topGifts: mapList(json['topGifts'], GirLiveTopGiftRow.fromJson),
      topGifters: mapList(json['topGifters'], GirLiveTopGifterRow.fromJson),
      pkCompleted: _int(json['pkCompleted']),
      pkWon: _int(json['pkWon']),
      pkLost: _int(json['pkLost']),
      pkDraw: _int(json['pkDraw']),
      tips: (json['tips'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          const [],
      comparePrevious: cmp,
    );
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }
}

class GirLiveTopGiftRow {
  const GirLiveTopGiftRow({
    required this.giftId,
    required this.name,
    required this.count,
    required this.jetonTotal,
  });

  final String giftId;
  final String name;
  final int count;
  final int jetonTotal;

  factory GirLiveTopGiftRow.fromJson(Map<String, dynamic> json) {
    return GirLiveTopGiftRow(
      giftId: json['giftId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      count: GirLivePublisherAssistantReport._int(json['count']) ?? 0,
      jetonTotal: GirLivePublisherAssistantReport._int(json['jetonTotal']) ?? 0,
    );
  }
}

class GirLiveTopGifterRow {
  const GirLiveTopGifterRow({
    required this.userId,
    required this.displayName,
    required this.giftCount,
    required this.jetonTotal,
  });

  final String userId;
  final String displayName;
  final int giftCount;
  final int jetonTotal;

  factory GirLiveTopGifterRow.fromJson(Map<String, dynamic> json) {
    return GirLiveTopGifterRow(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      giftCount: GirLivePublisherAssistantReport._int(json['giftCount']) ?? 0,
      jetonTotal: GirLivePublisherAssistantReport._int(json['jetonTotal']) ?? 0,
    );
  }
}

class GirLivePublisherCompare {
  const GirLivePublisherCompare({
    this.visitsDelta,
    this.grossJetonDelta,
    this.pkWinRateDelta,
  });

  final int? visitsDelta;
  final int? grossJetonDelta;
  final double? pkWinRateDelta;

  factory GirLivePublisherCompare.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return GirLivePublisherCompare(
      visitsDelta: GirLivePublisherAssistantReport._int(json['visitsDelta']),
      grossJetonDelta:
          GirLivePublisherAssistantReport._int(json['grossJetonDelta']),
      pkWinRateDelta: d(json['pkWinRateDelta']),
    );
  }
}
