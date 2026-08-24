import '../../../core/util/json_util.dart';

/// Backend oyun state alanlarını canonical biçimde okur.
abstract final class GameStateParser {
  static String? gameType(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final key in const [
      'gameType',
      'gameId',
      'gameSlug',
      'slug',
      'type',
    ]) {
      final value = raw[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value.toLowerCase();
    }
    return null;
  }

  static String normalizeGameType(String? value) {
    final v = value?.toLowerCase().trim() ?? '';
    if (v.contains('okey101') || v == 'okey-101') return 'okey101';
    if (v.contains('xox') || v.contains('tic')) return 'xox';
    return v;
  }

  static bool roomMatches({
    required String expectedRoomId,
    required Map<String, dynamic> raw,
    required String snapshotRoomId,
  }) {
    if (expectedRoomId.isEmpty) return true;
    if (snapshotRoomId.isNotEmpty && snapshotRoomId != expectedRoomId) {
      return false;
    }
    final fromRaw = pick(raw, ['roomId', 'id', '_id'])?.toString();
    if (fromRaw != null &&
        fromRaw.isNotEmpty &&
        fromRaw != expectedRoomId) {
      return false;
    }
    return true;
  }

  static List<String?> parseBoard(Map<String, dynamic> raw, {int size = 9}) {
    final candidates = [
      raw['board'],
      raw['grid'],
      raw['cells'],
      raw['state'] is Map ? asJsonMap(raw['state'])['board'] : null,
      raw['gameState'] is Map ? asJsonMap(raw['gameState'])['board'] : null,
    ];

    for (final candidate in candidates) {
      final parsed = _parseBoardValue(candidate, size: size);
      if (parsed != null) return parsed;
    }
    return List<String?>.filled(size, null);
  }

  static List<String?>? _parseBoardValue(dynamic value, {required int size}) {
    if (value is List) {
      final cells = value
          .map((cell) {
            if (cell == null) return null;
            final text = cell.toString().trim();
            if (text.isEmpty || text == '-' || text == '.') return null;
            return text;
          })
          .toList();
      if (cells.length >= size) return cells.take(size).toList();
      return [...cells, ...List.filled(size - cells.length, null)];
    }
    if (value is String && value.isNotEmpty) {
      final chars = value.split('');
      return List.generate(size, (i) {
        if (i >= chars.length) return null;
        final c = chars[i].trim();
        if (c.isEmpty || c == '-' || c == '.') return null;
        return c;
      });
    }
    return null;
  }

  static String? currentTurnPlayerId(Map<String, dynamic> raw) {
    for (final key in const [
      'currentTurn',
      'turn',
      'currentPlayer',
      'activePlayer',
      'currentPlayerId',
    ]) {
      final value = pick(raw, [key])?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static Iterable<String> playerIdentityAliases(Map<String, dynamic> raw) sync* {
    for (final key in const [
      'player1Id',
      'player2Id',
      'player1',
      'player2',
      'hostId',
    ]) {
      final value = pick(raw, [key])?.toString().trim();
      if (value != null && value.isNotEmpty) yield value;
    }

    final players = raw['players'];
    if (players is List) {
      for (final item in players) {
        final map = asJsonMap(item);
        for (final key in const ['id', 'userId', 'playerId', 'uid', 'gcid']) {
          final value = pick(map, [key])?.toString().trim();
          if (value != null && value.isNotEmpty) yield value;
        }
      }
    }
  }

  static bool isMyTurn({
    required Map<String, dynamic> raw,
    required String? userId,
  }) {
    if (userId == null || userId.isEmpty) return false;
    final turn = currentTurnPlayerId(raw);
    if (turn == null || turn.isEmpty) return false;
    if (turn == userId) return true;

    final p1 = pick(raw, ['player1Id', 'player1'])?.toString();
    final p2 = pick(raw, ['player2Id', 'player2'])?.toString();
    if (turn == 'player1' || turn == p1) return p1 == userId;
    if (turn == 'player2' || turn == p2) return p2 == userId;
    return false;
  }

  static List<Map<String, dynamic>> uniquePlayers(Map<String, dynamic> raw) {
    final seen = <String>{};
    final players = <Map<String, dynamic>>[];

    void addPlayer(Map<String, dynamic> map) {
      final id = pick(map, ['id', 'userId', 'playerId', 'uid', 'gcid'])
              ?.toString()
              .trim() ??
          pick(map, ['username', 'name'])?.toString().trim();
      if (id == null || id.isEmpty || seen.contains(id)) return;
      seen.add(id);
      players.add(map);
    }

    final list = raw['players'];
    if (list is List) {
      for (final item in list) {
        addPlayer(asJsonMap(item));
      }
    }

    if (players.isEmpty) {
      for (final slot in const [
        ('player1Id', 'player1Name'),
        ('player2Id', 'player2Name'),
      ]) {
        final id = pick(raw, [slot.$1])?.toString().trim();
        if (id == null || id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        players.add({
          'id': id,
          'name': pick(raw, [slot.$2])?.toString() ?? id,
        });
      }
    }
    return players;
  }

  static Map<String, int> parseScores(Map<String, dynamic> raw) {
    final scores = <String, int>{};
    for (final key in const ['player1Score', 'player2Score', 'score1', 'score2']) {
      final value = asInt(pick(raw, [key]));
      if (value != 0 || raw.containsKey(key)) scores[key] = value;
    }

    final nested = raw['scores'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        scores[entry.key.toString()] = asInt(entry.value);
      }
    }
    return scores;
  }

  static String? winner(Map<String, dynamic> raw) {
    for (final key in const ['winner', 'winnerId', 'result', 'outcome']) {
      final value = pick(raw, [key])?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String statusLabel(Map<String, dynamic> raw) {
    final status = pick(raw, ['status', 'state', 'phase'])?.toString().trim();
    return status == null || status.isEmpty ? 'waiting' : status;
  }

  static bool isFinished(Map<String, dynamic> raw) {
    final status = statusLabel(raw).toLowerCase();
    return status.contains('finish') ||
        status.contains('ended') ||
        status.contains('complete') ||
        winner(raw) != null;
  }

  static bool supportsBoard(String? gameType) {
    final type = normalizeGameType(gameType);
    return type == 'xox' ||
        type.contains('tic') ||
        type.contains('connect') ||
        type.contains('reversi') ||
        type.contains('gomoku');
  }
}
