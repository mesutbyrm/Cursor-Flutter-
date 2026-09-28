class DreamContest {
  final String id;
  final String title;
  final String description;
  final int maxEntries;
  final int currentEntries;
  final int votesPerUser;
  final int totalVotes;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? imageUrl;
  final int prizePool;

  DreamContest({
    required this.id,
    required this.title,
    required this.description,
    required this.maxEntries,
    required this.currentEntries,
    required this.votesPerUser,
    required this.totalVotes,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.imageUrl,
    required this.prizePool,
  });

  bool get isFull => currentEntries >= maxEntries;

  bool get isEnded => DateTime.now().isAfter(endDate);

  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays;
}

class DreamContestEntry {
  final String id;
  final String contestId;
  final String userId;
  final String username;
  final String dreamText;
  final String? avatarUrl;
  final int votes;
  final bool isWinner;
  final int rank;
  final DateTime createdAt;
  final int prizeWon;

  DreamContestEntry({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.username,
    required this.dreamText,
    this.avatarUrl,
    required this.votes,
    required this.isWinner,
    required this.rank,
    required this.createdAt,
    required this.prizeWon,
  });
}

class DreamInterpretation {
  final String id;
  final String symbol;
  final String meaning;
  final String interpretation;
  final String? imageUrl;
  final List<String> relatedSymbols;

  DreamInterpretation({
    required this.id,
    required this.symbol,
    required this.meaning,
    required this.interpretation,
    this.imageUrl,
    required this.relatedSymbols,
  });
}
