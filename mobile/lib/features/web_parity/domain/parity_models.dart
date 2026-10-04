import '../../../core/util/json_util.dart';

DateTime? parityDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

String parityStr(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

/// `{success,data}` zarfını açar; zarf yoksa gövdenin kendisini döndürür.
dynamic parityUnwrap(dynamic body) {
  if (body is Map && body.containsKey('data') && body['data'] != null) {
    return body['data'];
  }
  return body;
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderRole,
    required this.body,
    this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: parityStr(j['id']),
        senderRole: parityStr(j['senderRole'], 'user'),
        body: parityStr(j['body'] ?? j['message']),
        createdAt: parityDate(j['createdAt']),
      );

  final String id;
  final String senderRole;
  final String body;
  final DateTime? createdAt;

  bool get fromStaff => senderRole == 'admin';
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    this.priority = 'normal',
    this.lastMessageAt,
    this.createdAt,
    this.messageCount = 0,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) {
    final count = j['_count'] is Map ? asInt(asJsonMap(j['_count'])['messages']) : 0;
    final msgs = j['messages'] is List
        ? asJsonList(j['messages']).map(SupportMessage.fromJson).toList()
        : const <SupportMessage>[];
    return SupportTicket(
      id: parityStr(j['id']),
      subject: parityStr(j['subject'], 'Destek talebi'),
      category: parityStr(j['category'], 'general'),
      status: parityStr(j['status'], 'open'),
      priority: parityStr(j['priority'], 'normal'),
      lastMessageAt: parityDate(j['lastMessageAt']),
      createdAt: parityDate(j['createdAt']),
      messageCount: count > 0 ? count : msgs.length,
      messages: msgs,
    );
  }

  final String id;
  final String subject;
  final String category;
  final String status;
  final String priority;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final int messageCount;
  final List<SupportMessage> messages;

  bool get isClosed => status == 'closed';

  static const categories = <String, String>{
    'general': 'Genel',
    'payment': 'Ödeme',
    'account': 'Hesap',
    'technical': 'Teknik',
    'abuse': 'Kötüye kullanım',
  };

  static String categoryLabel(String c) => categories[c] ?? c;

  static String statusLabel(String s) => switch (s) {
        'open' => 'Açık',
        'pending' => 'Yanıtlandı',
        'resolved' => 'Çözüldü',
        'closed' => 'Kapalı',
        _ => s,
      };
}

class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.reason,
    required this.status,
    required this.amount,
    required this.currency,
    this.createdAt,
    this.paymentId,
    this.adminNote,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> j) => RefundRequest(
        id: parityStr(j['id']),
        reason: parityStr(j['reason']),
        status: parityStr(j['status'], 'pending'),
        amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0,
        currency: parityStr(j['currency'], 'TRY'),
        createdAt: parityDate(j['createdAt']),
        paymentId: j['paymentId']?.toString(),
        adminNote: (j['adminNote'] ?? j['note'])?.toString(),
      );

  final String id;
  final String reason;
  final String status;
  final double amount;
  final String currency;
  final DateTime? createdAt;
  final String? paymentId;
  final String? adminNote;

  static String statusLabel(String s) => switch (s) {
        'pending' => 'Bekliyor',
        'approved' => 'Onaylandı',
        'rejected' => 'Reddedildi',
        'refunded' => 'İade edildi',
        _ => s,
      };
}

class MembershipPlanInfo {
  const MembershipPlanInfo({
    required this.id,
    required this.name,
    required this.tier,
    required this.durationDays,
    required this.priceType,
    required this.price,
    this.description,
    this.discountPercent = 0,
    this.bonusJetons = 0,
    this.isFeatured = false,
  });

  factory MembershipPlanInfo.fromJson(Map<String, dynamic> j) =>
      MembershipPlanInfo(
        id: parityStr(j['id']),
        name: parityStr(j['name'], 'Üyelik'),
        tier: parityStr(j['tier'], 'basic'),
        durationDays: asInt(j['durationDays']),
        priceType: parityStr(j['priceType'], 'jeton'),
        price: asInt(j['price']),
        description: j['description']?.toString(),
        discountPercent: asInt(j['discountPercent']),
        bonusJetons: asInt(j['bonusJetons']),
        isFeatured: j['isFeatured'] == true,
      );

  final String id;
  final String name;
  final String tier;
  final int durationDays;
  final String priceType;
  final int price;
  final String? description;
  final int discountPercent;
  final int bonusJetons;
  final bool isFeatured;

  /// Hediye yalnızca jeton/CFC ile ödenir.
  bool get giftable => priceType == 'jeton';
}

class ComparisonTier {
  const ComparisonTier({required this.key, required this.name});

  factory ComparisonTier.fromJson(Map<String, dynamic> j) => ComparisonTier(
        key: parityStr(j['key'] ?? j['id']),
        name: parityStr(j['name'] ?? j['label'] ?? j['nameTr'] ?? j['key']),
      );

  final String key;
  final String name;
}

class ComparisonFeature {
  const ComparisonFeature({
    required this.key,
    required this.name,
    required this.category,
    required this.cells,
    this.description,
  });

  factory ComparisonFeature.fromJson(Map<String, dynamic> j) {
    final cells = <String, String>{};
    final raw = j['cells'];
    if (raw is Map) {
      raw.forEach((k, v) {
        cells[k.toString()] = v is Map ? parityStr(v['display'], '—') : '—';
      });
    }
    return ComparisonFeature(
      key: parityStr(j['key']),
      name: parityStr(j['name'], parityStr(j['key'])),
      category: parityStr(j['category'], 'Genel'),
      description: j['description']?.toString(),
      cells: cells,
    );
  }

  final String key;
  final String name;
  final String category;
  final String? description;
  final Map<String, String> cells;
}

class MembershipComparison {
  const MembershipComparison({required this.tiers, required this.features});

  factory MembershipComparison.fromJson(Map<String, dynamic> j) =>
      MembershipComparison(
        tiers: asJsonList(j['tiers']).map(ComparisonTier.fromJson).toList(),
        features:
            asJsonList(j['features']).map(ComparisonFeature.fromJson).toList(),
      );

  final List<ComparisonTier> tiers;
  final List<ComparisonFeature> features;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    this.userId,
    this.username,
    this.image,
    this.score = 0,
    this.subtitle,
    this.isSelf = false,
  });

  factory LeaderboardEntry.fromTop100(Map<String, dynamic> j, {String? selfId}) {
    final uid = j['userId']?.toString();
    return LeaderboardEntry(
      rank: asInt(j['rank']),
      userId: uid,
      name: parityStr(j['name'] ?? j['username'], 'Kullanıcı'),
      username: j['username']?.toString(),
      image: j['image']?.toString(),
      score: asInt(j['score']),
      isSelf: selfId != null && uid == selfId,
    );
  }

  factory LeaderboardEntry.fromVip(Map<String, dynamic> j) => LeaderboardEntry(
        rank: asInt(j['rank']),
        userId: j['userId']?.toString(),
        name: parityStr(j['name'], 'Kullanıcı'),
        image: j['image']?.toString(),
        score: asInt(j['xp']),
        subtitle: 'Seviye ${asInt(j['level'])} · ${parityStr(j['tier'], 'basic')}',
        isSelf: j['isSelf'] == true,
      );

  final int rank;
  final String? userId;
  final String name;
  final String? username;
  final String? image;
  final int score;
  final String? subtitle;
  final bool isSelf;
}

class LeaderboardResult {
  const LeaderboardResult({
    required this.entries,
    this.periodKey,
    this.endTime,
    this.selfRank,
  });

  final List<LeaderboardEntry> entries;
  final String? periodKey;
  final DateTime? endTime;
  final int? selfRank;
}

class SupporterLevelRow {
  const SupporterLevelRow({
    required this.level,
    required this.levelName,
    required this.totalContributed,
    this.broadcasterId,
    this.userId,
  });

  factory SupporterLevelRow.fromJson(Map<String, dynamic> j) =>
      SupporterLevelRow(
        level: asInt(j['level']),
        levelName: parityStr(j['levelName'], 'Seviye ${asInt(j['level'])}'),
        totalContributed: asInt(j['totalContributed']),
        broadcasterId: j['broadcasterId']?.toString(),
        userId: j['userId']?.toString(),
      );

  final int level;
  final String levelName;
  final int totalContributed;
  final String? broadcasterId;
  final String? userId;
}
