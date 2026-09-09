import '../../../core/util/json_util.dart';

/// Hediye defteri satırı — admin ledger veya denetim kaydı.
class AdminGiftLedgerRow {
  const AdminGiftLedgerRow({
    this.giftName,
    this.giftId,
    this.senderName,
    this.receiverName,
    this.amount = 1,
    this.context,
    this.at,
    this.raw = const {},
  });

  final String? giftName;
  final String? giftId;
  final String? senderName;
  final String? receiverName;
  final int amount;
  final String? context;
  final DateTime? at;
  final Map<String, dynamic> raw;

  static AdminGiftLedgerRow fromMap(Map<String, dynamic> m) {
    int readInt(List<String> keys) {
      for (final k in keys) {
        final v = pick(m, [k]);
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
        }
      }
      return 1;
    }

    DateTime? readDate() {
      for (final k in ['createdAt', 'sentAt', 'timestamp', 'at']) {
        final v = m[k]?.toString();
        if (v == null || v.isEmpty) continue;
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.toLocal();
      }
      return null;
    }

    String? readUser(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
        if (v is Map) {
          final map = asJsonMap(v);
          final name = pick(map, ['displayName', 'username', 'name']);
          if (name != null) return name.toString();
        }
      }
      return null;
    }

    return AdminGiftLedgerRow(
      giftName: pick(m, ['giftName', 'name', 'title'])?.toString(),
      giftId: pick(m, ['giftId', 'id'])?.toString(),
      senderName: readUser(['senderName', 'sender', 'fromUser', 'from']),
      receiverName: readUser(['receiverName', 'receiver', 'toUser', 'to']),
      amount: readInt(['amount', 'count', 'quantity', 'coins']),
      context: pick(m, ['context', 'source', 'roomType', 'channel'])?.toString(),
      at: readDate(),
      raw: m,
    );
  }
}

/// Yayın / oda geçmişi satırı.
class AdminBroadcastHistoryRow {
  const AdminBroadcastHistoryRow({
    this.id,
    this.title,
    this.kind = 'stream',
    this.startedAt,
    this.durationSec,
    this.viewers,
    this.raw = const {},
  });

  final String? id;
  final String? title;
  final String kind;
  final DateTime? startedAt;
  final int? durationSec;
  final int? viewers;
  final Map<String, dynamic> raw;

  static AdminBroadcastHistoryRow fromMap(
    Map<String, dynamic> m, {
    String defaultKind = 'stream',
  }) {
    DateTime? readDate() {
      for (final k in ['startedAt', 'createdAt', 'startTime', 'openedAt']) {
        final v = m[k]?.toString();
        if (v == null || v.isEmpty) continue;
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.toLocal();
      }
      return null;
    }

    final kind = pick(m, ['kind', 'type', 'roomType'])?.toString() ?? defaultKind;

    return AdminBroadcastHistoryRow(
      id: pick(m, ['id', 'roomId', 'streamId'])?.toString(),
      title: pick(m, ['title', 'name', 'roomName'])?.toString(),
      kind: kind,
      startedAt: readDate(),
      durationSec: pick(m, ['durationSec', 'duration']) is num
          ? (pick(m, ['durationSec', 'duration']) as num).toInt()
          : null,
      viewers: pick(m, ['viewers', 'viewerCount', 'participants']) is num
          ? (pick(m, ['viewers', 'viewerCount', 'participants']) as num).toInt()
          : null,
      raw: m,
    );
  }
}

/// Canlı falcı kaydı özeti.
class AdminLiveTellerSummary {
  const AdminLiveTellerSummary({
    required this.tellerId,
    this.userId,
    this.displayName,
    this.status,
    this.isVerified = false,
    this.isActive = true,
    this.raw = const {},
  });

  final String tellerId;
  final String? userId;
  final String? displayName;
  final String? status;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic> raw;

  static AdminLiveTellerSummary? fromMap(Map<String, dynamic> m) {
    final id = pick(m, ['id', 'tellerId', '_id'])?.toString();
    if (id == null || id.isEmpty) return null;
    final verified = m['isVerified'];
    return AdminLiveTellerSummary(
      tellerId: id,
      userId: pick(m, ['userId', 'user', 'uid'])?.toString(),
      displayName: pick(m, ['displayName', 'name'])?.toString(),
      status: pick(m, [
        'status',
        'applicationStatus',
        'approvalStatus',
      ])?.toString(),
      isVerified: verified == true || verified == 'true' || verified == 1,
      isActive: m['isActive'] != false && m['isActive'] != 'false',
      raw: m,
    );
  }
}

List<AdminGiftLedgerRow> parseGiftLedgerRows(dynamic data) {
  final list = _flattenRows(data, keys: ['gifts', 'ledger', 'items', 'history']);
  return list.map(AdminGiftLedgerRow.fromMap).toList(growable: false);
}

List<AdminBroadcastHistoryRow> parseBroadcastHistoryRows(
  dynamic data, {
  String defaultKind = 'stream',
}) {
  final list = _flattenRows(data, keys: ['streams', 'rooms', 'items', 'history']);
  return list
      .map((m) => AdminBroadcastHistoryRow.fromMap(m, defaultKind: defaultKind))
      .toList(growable: false);
}

List<AdminLiveTellerSummary> parseLiveTellerList(dynamic data) {
  final list = _flattenRows(data, keys: ['tellers', 'items', 'data']);
  return list
      .map(AdminLiveTellerSummary.fromMap)
      .whereType<AdminLiveTellerSummary>()
      .toList(growable: false);
}

List<Map<String, dynamic>> _flattenRows(
  dynamic data, {
  required List<String> keys,
}) {
  if (data is List) {
    return data.map((e) => asJsonMap(e)).toList();
  }
  if (data is! Map) return const [];

  final map = asJsonMap(data);
  if (map['success'] == true && map['data'] != null) {
    return _flattenRows(map['data'], keys: keys);
  }
  for (final key in keys) {
    final val = map[key];
    if (val is List) {
      return val.map((e) => asJsonMap(e)).toList();
    }
  }
  if (map.isNotEmpty && map.values.every((v) => v is! List)) {
    return [map];
  }
  return const [];
}
