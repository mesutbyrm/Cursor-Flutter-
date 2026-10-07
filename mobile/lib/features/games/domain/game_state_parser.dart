import 'dart:convert';
import 'dart:math' as math;

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

  /// Oyun durumu nesnesi. `GET /api/games/room/{id}` `state` alanını JSON
  /// **metni** olarak döner (`JSON.stringify`); hem Map hem metin okunur.
  static Map<String, dynamic>? stateMap(Map<String, dynamic> raw) {
    for (final key in const ['state', 'gameState']) {
      final v = raw[key];
      if (v is Map) return asJsonMap(v);
      if (v is String && v.trimLeft().startsWith('{')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map) return asJsonMap(decoded);
        } on FormatException {
          continue;
        }
      }
    }
    return null;
  }

  /// Kare tahtanın kenar uzunluğu — XOX NxN (`state.size`, 3–30), yoksa
  /// tam kare hücre sayısından; bilinmiyorsa 3.
  static int boardColumns(Map<String, dynamic> raw) {
    final size = asInt(stateMap(raw)?['size'] ?? raw['gridSize']);
    if (size >= 3 && size <= 30) return size;
    final board = _rawBoard(raw);
    if (board is List && board.length > 9) {
      final n = math.sqrt(board.length).round();
      if (n * n == board.length) return n;
    }
    return 3;
  }

  static dynamic _rawBoard(Map<String, dynamic> raw) {
    final state = stateMap(raw);
    return raw['board'] ?? raw['grid'] ?? raw['cells'] ?? state?['board'];
  }

  /// Bağlantı koptuğunda masayı yapay zekâ devralır (`isAI` + kopan
  /// oyuncu `disconnectedPlayerId`); o oyuncu `replace-ai` ile geri döner.
  static bool canReclaimFromAi(Map<String, dynamic> raw, String? userId) {
    final uid = userId?.trim() ?? '';
    if (uid.isEmpty) return false;
    final status = raw['status']?.toString().toLowerCase() ?? '';
    return asBool(raw['isAI']) &&
        status == 'active' &&
        raw['disconnectedPlayerId']?.toString() == uid;
  }

  static List<String?> parseBoard(Map<String, dynamic> raw, {int? size}) {
    final cols = boardColumns(raw);
    size ??= cols * cols;
    final state = stateMap(raw);
    final candidates = [
      raw['board'],
      raw['grid'],
      raw['cells'],
      state?['board'],
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
