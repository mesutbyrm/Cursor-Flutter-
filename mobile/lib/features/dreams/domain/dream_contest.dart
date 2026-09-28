import '../../../core/util/json_util.dart';

/// `GET /api/dream-contest` → `contests[]` (Prisma `DreamContest`).
class DreamContest {
  const DreamContest({
    required this.id,
    required this.title,
    required this.description,
    required this.dreamPrompt,
    required this.startDate,
    required this.endDate,
    required this.isOngoing,
    required this.isEnded,
    required this.entryCount,
  });

  final String id;
  final String title;
  final String description;
  final String dreamPrompt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOngoing;
  final bool isEnded;
  final int entryCount;

  bool get acceptsEntries => !isEnded;

  factory DreamContest.fromJson(Map<String, dynamic> json) => DreamContest(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dreamPrompt: json['dreamPrompt']?.toString() ?? '',
        startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
        isOngoing: json['isOngoing'] == true,
        isEnded: json['isEnded'] == true,
        entryCount: asInt(json['entryCount']),
      );
}

/// `GET /api/dream-contest/{id}/entries` → `entries[]`.
class DreamContestEntry {
  const DreamContestEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.interpretation,
    required this.voteCount,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String interpretation;
  final int voteCount;

  factory DreamContestEntry.fromJson(Map<String, dynamic> json) {
    final user = asJsonMap(json['user']);
    final name = user['name']?.toString().trim();
    final username = user['username']?.toString().trim();
    return DreamContestEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      userName: (name != null && name.isNotEmpty)
          ? name
          : (username != null && username.isNotEmpty ? '@$username' : 'Kullanıcı'),
      userImage: user['image']?.toString(),
      interpretation: json['interpretation']?.toString() ?? '',
      voteCount: asInt(json['voteCount']),
    );
  }
}

class DreamContestEntries {
  const DreamContestEntries({
    required this.entries,
    required this.votedEntryIds,
  });

  final List<DreamContestEntry> entries;
  final Set<String> votedEntryIds;

  factory DreamContestEntries.fromJson(Map<String, dynamic> json) {
    final voted = json['userVotedEntryIds'];
    return DreamContestEntries(
      entries: asJsonList(json['entries'])
          .map(DreamContestEntry.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList(),
      votedEntryIds: voted is List ? voted.map((e) => e.toString()).toSet() : {},
    );
  }
}
