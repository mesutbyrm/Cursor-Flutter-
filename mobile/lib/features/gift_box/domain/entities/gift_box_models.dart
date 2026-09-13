import '../../../../core/util/json_util.dart';

/// BÖLÜM 22 — hediye kutusu listesi / tek kutu (sunucu alanları, uydurma yok).
class GiftBoxLimits {
  const GiftBoxLimits({
    required this.minAmount,
    required this.maxAmount,
    required this.maxWinners,
    required this.allowedDurations,
  });

  final int minAmount;
  final int maxAmount;
  final int maxWinners;
  final List<int> allowedDurations;

  static GiftBoxLimits fromJson(Map<String, dynamic>? json) {
    final m = json ?? {};
    final durations = pick(m, ['allowedDurations', 'durations']);
    List<int> parsed = const [5, 10, 15, 30, 60, 120];
    if (durations is List) {
      parsed = durations
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((n) => n > 0)
          .toList(growable: false);
      if (parsed.isEmpty) parsed = const [5, 10, 15, 30, 60, 120];
    }
    return GiftBoxLimits(
      minAmount: _int(m, ['minAmount', 'min'], 10),
      maxAmount: _int(m, ['maxAmount', 'max'], 100000),
      maxWinners: _int(m, ['maxWinners'], 100),
      allowedDurations: parsed,
    );
  }
}

class GiftBoxSummary {
  const GiftBoxSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.winnerCount,
    required this.remainingWinners,
    required this.remainingSec,
    required this.remainingAmount,
    required this.taskType,
    this.creatorId,
    this.taskTargetUserId,
    this.isOwner = false,
    this.hasJoined = false,
  });

  final String id;
  final String status;
  final int totalAmount;
  final int winnerCount;
  final int remainingWinners;
  final int remainingSec;
  final int remainingAmount;
  final String taskType;
  final String? creatorId;
  final String? taskTargetUserId;
  final bool isOwner;
  final bool hasJoined;

  bool get isActive => status == 'active';

  GiftBoxSummary withFlags({bool? isOwner, bool? hasJoined}) {
    return GiftBoxSummary(
      id: id,
      status: status,
      totalAmount: totalAmount,
      winnerCount: winnerCount,
      remainingWinners: remainingWinners,
      remainingSec: remainingSec,
      remainingAmount: remainingAmount,
      taskType: taskType,
      creatorId: creatorId,
      taskTargetUserId: taskTargetUserId,
      isOwner: isOwner ?? this.isOwner,
      hasJoined: hasJoined ?? this.hasJoined,
    );
  }

  static GiftBoxSummary? tryParse(Map<String, dynamic> raw) {
    final id = (pick(raw, ['id', 'boxId']) ?? '').toString();
    if (id.isEmpty) return null;
    return GiftBoxSummary(
      id: id,
      status: (pick(raw, ['status']) ?? 'active').toString(),
      totalAmount: _int(raw, ['totalAmount', 'amount'], 0),
      winnerCount: _int(raw, ['winnerCount'], 0),
      remainingWinners: _int(raw, ['remainingWinners'], 0),
      remainingSec: _int(raw, ['remainingSec', 'remainingSeconds'], 0),
      remainingAmount: _int(raw, ['remainingAmount'], 0),
      taskType: (pick(raw, ['taskType']) ?? 'none').toString(),
      creatorId: pick(raw, ['creatorId', 'ownerId'])?.toString(),
      taskTargetUserId: pick(raw, ['taskTargetUserId'])?.toString(),
      isOwner: raw['isOwner'] == true || raw['meIsOwner'] == true,
      hasJoined: raw['hasJoined'] == true || raw['joined'] == true,
    );
  }
}

class GiftBoxListSnapshot {
  const GiftBoxListSnapshot({
    required this.boxes,
    required this.limits,
    this.openBoxId,
    this.meJoinedBoxIds = const {},
  });

  final List<GiftBoxSummary> boxes;
  final GiftBoxLimits limits;
  final String? openBoxId;
  final Set<String> meJoinedBoxIds;

  GiftBoxSummary? get primaryActive {
    for (final b in boxes) {
      if (b.isActive) return b;
    }
    return null;
  }

  static GiftBoxListSnapshot fromApi(Map<String, dynamic> raw) {
    final root = raw;
    final limits = GiftBoxLimits.fromJson(
      asJsonMap(pick(root, ['limits', 'giftBoxLimits'])),
    );
    final me = asJsonMap(pick(root, ['me']));
    final joined = <String>{};
    final joinedList = pick(me, ['joinedBoxIds', 'boxesJoined']);
    if (joinedList is List) {
      for (final e in joinedList) {
        final s = e.toString();
        if (s.isNotEmpty) joined.add(s);
      }
    }
    final openId = pick(root, ['openBoxId', 'myOpenBoxId'])?.toString();

    final listRaw = pick(root, ['boxes', 'active', 'items', 'giftBoxes']);
    final boxes = <GiftBoxSummary>[];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map) {
          final box = GiftBoxSummary.tryParse(Map<String, dynamic>.from(e));
          if (box != null) {
            boxes.add(
              box.withFlags(
                hasJoined:
                    joined.contains(box.id) || me['joinedBoxId'] == box.id,
                isOwner: me['userId']?.toString() == box.creatorId ||
                    openId == box.id,
              ),
            );
          }
        }
      }
    }
    final single = GiftBoxSummary.tryParse(root);
    if (single != null && boxes.every((b) => b.id != single.id)) {
      boxes.insert(0, single);
    }
    return GiftBoxListSnapshot(
      boxes: boxes,
      limits: limits,
      openBoxId: openId,
      meJoinedBoxIds: joined,
    );
  }
}

int _int(Map<String, dynamic> m, List<String> keys, int def) {
  final v = pick(m, keys);
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? def;
}

String giftBoxTaskLabel(String taskType) {
  return switch (taskType) {
    'follow_creator' => 'Kutu sahibini takip et',
    'follow_broadcaster' => 'Yayıncıyı takip et',
    'follow_user' => 'Belirtilen kullanıcıyı takip et',
    'share' => 'Yayını/odayı paylaş',
    _ => 'Görev yok',
  };
}
