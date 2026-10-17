/// DJ isteği (!istek şarkıcı şarkı) — oda sahibi / DJ telefonundan çalar.
class DjRequest {
  const DjRequest({
    required this.id,
    required this.status,
    required this.query,
    required this.cost,
    required this.userId,
    required this.userName,
    this.handlerId,
    this.handlerName,
    this.createdAtMs = 0,
    this.updatedAtMs = 0,
  });

  final String id;
  /// pending | playing | done | rejected | expired | cancelled
  final String status;
  final String query;
  final int cost;
  final String userId;
  final String userName;
  final String? handlerId;
  final String? handlerName;
  final int createdAtMs;
  final int updatedAtMs;

  bool get isPending => status == 'pending';
  bool get isPlaying => status == 'playing';

  static DjRequest? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    String? opt(Object? v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return DjRequest(
      id: id,
      status: raw['status']?.toString() ?? 'pending',
      query: raw['query']?.toString() ?? '',
      cost: asInt(raw['cost']),
      userId: raw['userId']?.toString() ?? '',
      userName: raw['userName']?.toString() ?? 'Biri',
      handlerId: opt(raw['handlerId']),
      handlerName: opt(raw['handlerName']),
      createdAtMs: asInt(raw['createdAtMs']),
      updatedAtMs: asInt(raw['updatedAtMs']),
    );
  }
}

/// Odanın açık DJ istekleri + isteği yanıtlayabilecek kişiler.
class DjRequestsSnapshot {
  const DjRequestsSnapshot({
    this.pending = const [],
    this.playing,
    this.handlerIds = const [],
    this.loaded = false,
  });

  final List<DjRequest> pending;
  final DjRequest? playing;
  /// Açılır pencere hedefleri: oda sahibi odadaysa o, değilse aktif DJ'ler.
  final List<String> handlerIds;
  final bool loaded;

  bool isHandler(String? userId) =>
      userId != null && userId.isNotEmpty && handlerIds.contains(userId);

  static DjRequestsSnapshot fromJson(Object? raw) {
    if (raw is! Map) return const DjRequestsSnapshot(loaded: true);
    final pending = <DjRequest>[];
    final list = raw['pending'];
    if (list is List) {
      for (final e in list) {
        final r = DjRequest.fromJson(e);
        if (r != null) pending.add(r);
      }
    }
    final handlers = raw['handlerIds'];
    return DjRequestsSnapshot(
      pending: pending,
      playing: DjRequest.fromJson(raw['playing']),
      handlerIds: handlers is List
          ? handlers.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      loaded: true,
    );
  }
}
