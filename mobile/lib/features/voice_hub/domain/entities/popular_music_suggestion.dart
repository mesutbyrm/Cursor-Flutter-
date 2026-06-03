class PopularMusicSuggestion {
  const PopularMusicSuggestion({
    required this.title,
    required this.artist,
    required this.query,
  });

  factory PopularMusicSuggestion.fromJson(Map<String, dynamic> json) {
    return PopularMusicSuggestion(
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      query: json['query']?.toString() ?? json['title']?.toString() ?? '',
    );
  }

  final String title;
  final String artist;
  final String query;
}
