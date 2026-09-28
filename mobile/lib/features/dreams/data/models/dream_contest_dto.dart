import '../../domain/entities/dream_contest_entity.dart';

class DreamContestDTO {
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

  DreamContestDTO({
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

  factory DreamContestDTO.fromJson(Map<String, dynamic> json) {
    return DreamContestDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      maxEntries: (json['maxEntries'] as num?)?.toInt() ?? 100,
      currentEntries: (json['currentEntries'] as num?)?.toInt() ?? 0,
      votesPerUser: (json['votesPerUser'] as num?)?.toInt() ?? 1,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now().add(const Duration(days: 7)),
      isActive: json['isActive'] == true,
      imageUrl: json['imageUrl']?.toString(),
      prizePool: (json['prizePool'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'maxEntries': maxEntries,
        'currentEntries': currentEntries,
        'votesPerUser': votesPerUser,
        'totalVotes': totalVotes,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive,
        'imageUrl': imageUrl,
        'prizePool': prizePool,
      };

  DreamContest toDomain() => DreamContest(
        id: id,
        title: title,
        description: description,
        maxEntries: maxEntries,
        currentEntries: currentEntries,
        votesPerUser: votesPerUser,
        totalVotes: totalVotes,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        imageUrl: imageUrl,
        prizePool: prizePool,
      );
}

class DreamContestEntryDTO {
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

  DreamContestEntryDTO({
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

  factory DreamContestEntryDTO.fromJson(Map<String, dynamic> json) {
    return DreamContestEntryDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      contestId: json['contestId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      dreamText: json['dreamText']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      isWinner: json['isWinner'] == true,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      prizeWon: (json['prizeWon'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'contestId': contestId,
        'userId': userId,
        'username': username,
        'dreamText': dreamText,
        'avatarUrl': avatarUrl,
        'votes': votes,
        'isWinner': isWinner,
        'rank': rank,
        'createdAt': createdAt.toIso8601String(),
        'prizeWon': prizeWon,
      };

  DreamContestEntry toDomain() => DreamContestEntry(
        id: id,
        contestId: contestId,
        userId: userId,
        username: username,
        dreamText: dreamText,
        avatarUrl: avatarUrl,
        votes: votes,
        isWinner: isWinner,
        rank: rank,
        createdAt: createdAt,
        prizeWon: prizeWon,
      );
}

class DreamInterpretationDTO {
  final String id;
  final String symbol;
  final String meaning;
  final String interpretation;
  final String? imageUrl;
  final List<String> relatedSymbols;

  DreamInterpretationDTO({
    required this.id,
    required this.symbol,
    required this.meaning,
    required this.interpretation,
    this.imageUrl,
    required this.relatedSymbols,
  });

  factory DreamInterpretationDTO.fromJson(Map<String, dynamic> json) {
    return DreamInterpretationDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      interpretation: json['interpretation']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      relatedSymbols: List<String>.from(
        (json['relatedSymbols'] as List<dynamic>?)?.map((e) => e.toString()) ??
            [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'symbol': symbol,
        'meaning': meaning,
        'interpretation': interpretation,
        'imageUrl': imageUrl,
        'relatedSymbols': relatedSymbols,
      };

  DreamInterpretation toDomain() => DreamInterpretation(
        id: id,
        symbol: symbol,
        meaning: meaning,
        interpretation: interpretation,
        imageUrl: imageUrl,
        relatedSymbols: relatedSymbols,
      );
}
