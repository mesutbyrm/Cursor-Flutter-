import 'dart:convert';
import 'dart:math' as math;

import '../../../../core/util/json_util.dart';

/// SOS oyun durumu — `GET /api/games/sos/{id}` (Prisma `SosGame` satırı).
/// `board` ve `lines` sunucuda JSON **metni** olarak saklanır.
class SosGameState {
  const SosGameState({
    required this.id,
    required this.gridSize,
    required this.board,
    required this.lines,
    required this.currentTurn,
    required this.status,
    this.player1Id,
    this.player2Id,
    this.player1Name = 'Oyuncu 1',
    this.player2Name = 'Oyuncu 2',
    this.player1Score = 0,
    this.player2Score = 0,
    this.isAI = false,
    this.winnerId,
    this.disconnectedPlayerId,
  });

  factory SosGameState.fromJson(Map<String, dynamic> json) {
    final data = json['game'] is Map ? asJsonMap(json['game']) : json;
    final size = asInt(data['gridSize']).clamp(3, 30);
    return SosGameState(
      id: data['id']?.toString() ?? '',
      gridSize: size,
      board: _parseBoard(data['board'], size),
      lines: _parseLines(data['lines']),
      currentTurn: asInt(data['currentTurn']) == 2 ? 2 : 1,
      status: data['status']?.toString() ?? '',
      player1Id: data['player1Id']?.toString(),
      player2Id: data['player2Id']?.toString(),
      player1Name: data['player1Name']?.toString() ?? 'Oyuncu 1',
      player2Name: data['player2Name']?.toString() ?? 'Oyuncu 2',
      player1Score: asInt(data['player1Score']),
      player2Score: asInt(data['player2Score']),
      isAI: asBool(data['isAI']),
      winnerId: data['winnerId']?.toString(),
      disconnectedPlayerId: data['disconnectedPlayerId']?.toString(),
    );
  }

  final String id;
  final int gridSize;
  final List<List<String>> board;
  final List<List<int>> lines;
  final int currentTurn;
  final String status;
  final String? player1Id;
  final String? player2Id;
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final bool isAI;
  final String? winnerId;
  final String? disconnectedPlayerId;

  bool get isActive => status == 'active';
  bool get isWaiting => status == 'waiting';
  bool get isFinished => status == 'completed' || status == 'cancelled';

  /// Kullanıcının oyuncu numarası (1/2), izleyiciyse `null`.
  int? playerNumberOf(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    if (userId == player1Id) return 1;
    if (userId == player2Id) return 2;
    return null;
  }

  bool isMyTurn(String? userId) =>
      isActive && playerNumberOf(userId) == currentTurn;

  static List<List<String>> _parseBoard(dynamic raw, int size) {
    dynamic v = raw;
    if (v is String && v.trim().startsWith('[')) {
      try {
        v = jsonDecode(v);
      } on FormatException {
        v = null;
      }
    }
    final out = List.generate(size, (_) => List.filled(size, ''));
    if (v is List) {
      for (var r = 0; r < size && r < v.length; r++) {
        final row = v[r];
        if (row is! List) continue;
        for (var c = 0; c < size && c < row.length; c++) {
          final cell = row[c]?.toString() ?? '';
          out[r][c] = cell == 'S' || cell == 'O' ? cell : '';
        }
      }
    }
    return out;
  }

  static List<List<int>> _parseLines(dynamic raw) {
    dynamic v = raw;
    if (v is String && v.trim().startsWith('[')) {
      try {
        v = jsonDecode(v);
      } on FormatException {
        v = null;
      }
    }
    if (v is! List) return const [];
    return v
        .whereType<List>()
        .map((l) => l.map(asInt).toList())
        .where((l) => l.length == 6)
        .toList();
  }
}

/// SOS kuralları — web (`app/[lang]/oyunlar/sos/page.tsx`) ve sunucu
/// (`app/api/games/sos/[gameId]`) ile aynı `findNewSOS` mantığı.
/// Çizgi biçimi: `[r1, c1, r2, c2, r3, c3]`.
abstract final class SosEngine {
  static const _directions = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];

  static List<List<int>> findNewLines(
    List<List<String>> board,
    int row,
    int col,
    List<List<int>> existing,
    int size,
  ) {
    final out = <List<int>>[];
    final seen = existing.map((l) => l.join(',')).toSet();
    for (final d in _directions) {
      final dr = d[0], dc = d[1];
      final checks = [
        [
          [row, col],
          [row + dr, col + dc],
          [row + 2 * dr, col + 2 * dc],
        ],
        [
          [row - dr, col - dc],
          [row, col],
          [row + dr, col + dc],
        ],
        [
          [row - 2 * dr, col - 2 * dc],
          [row - dr, col - dc],
          [row, col],
        ],
      ];
      for (final pos in checks) {
        final inBounds = pos.every(
          (p) => p[0] >= 0 && p[0] < size && p[1] >= 0 && p[1] < size,
        );
        if (!inBounds) continue;
        if (board[pos[0][0]][pos[0][1]] != 'S' ||
            board[pos[1][0]][pos[1][1]] != 'O' ||
            board[pos[2][0]][pos[2][1]] != 'S') {
          continue;
        }
        final key = [...pos[0], ...pos[1], ...pos[2]];
        if (seen.add(key.join(','))) out.add(key);
      }
    }
    return out;
  }

  static bool isFull(List<List<String>> board) =>
      board.every((r) => r.every((c) => c.isNotEmpty));

  /// Web'deki yapay zekâ: puan getiren ilk hamle, yoksa rastgele hücre/harf.
  static ({int row, int col, String letter})? aiMove(
    List<List<String>> board,
    List<List<int>> existing,
    int size, {
    math.Random? random,
  }) {
    final rnd = random ?? math.Random();
    final empty = <(int, int)>[
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (board[r][c].isEmpty) (r, c),
    ];
    if (empty.isEmpty) return null;
    for (final (r, c) in empty) {
      for (final letter in const ['S', 'O']) {
        board[r][c] = letter;
        final scored = findNewLines(board, r, c, existing, size).isNotEmpty;
        board[r][c] = '';
        if (scored) return (row: r, col: c, letter: letter);
      }
    }
    final (r, c) = empty[rnd.nextInt(empty.length)];
    return (row: r, col: c, letter: rnd.nextBool() ? 'S' : 'O');
  }

  /// Yapay zekâ masasında insan hamlesi + yapay zekâ cevabı — web ile aynı
  /// `aiMoves` gövdesi (`PATCH /api/games/sos/{id}`).
  static Map<String, dynamic> playAgainstAi({
    required SosGameState game,
    required String userId,
    required int row,
    required int col,
    required String letter,
    math.Random? random,
  }) {
    final size = game.gridSize;
    final board = [for (final r in game.board) [...r]];
    var lines = [for (final l in game.lines) [...l]];
    board[row][col] = letter;
    final scored = findNewLines(board, row, col, lines, size);
    lines = [...lines, ...scored];

    final isP1 = game.player1Id == userId;
    var p1 = game.player1Score + (isP1 ? scored.length : 0);
    var p2 = game.player2Score + (!isP1 ? scored.length : 0);

    final aiNum = game.disconnectedPlayerId == game.player1Id ? 1 : 2;
    final humanNum = aiNum == 1 ? 2 : 1;
    var turn = scored.isNotEmpty ? humanNum : aiNum;
    var gameOver = isFull(board);

    if (!gameOver && turn == aiNum) {
      var keepPlaying = true;
      while (keepPlaying && !gameOver) {
        final move = aiMove(board, lines, size, random: random);
        if (move == null) {
          gameOver = true;
          break;
        }
        board[move.row][move.col] = move.letter;
        final aiScored =
            findNewLines(board, move.row, move.col, lines, size);
        lines = [...lines, ...aiScored];
        if (aiNum == 1) {
          p1 += aiScored.length;
        } else {
          p2 += aiScored.length;
        }
        gameOver = isFull(board);
        if (aiScored.isEmpty || gameOver) keepPlaying = false;
      }
      turn = humanNum;
    }

    return {
      'row': row,
      'col': col,
      'letter': letter,
      'aiMoves': {
        'board': board,
        'lines': lines,
        'player1Score': p1,
        'player2Score': p2,
        'currentTurn': turn,
        'gameOver': gameOver,
        // Web ile aynı: oyuncu kazanırsa kendi kimliği, aksi halde null.
        if (gameOver) 'winnerId': p1 > p2 ? userId : null,
      },
    };
  }
}
