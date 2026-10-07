import '../../../core/util/json_util.dart';

/// `{success, data: {...}}` zarfını açar; zarf yoksa gövdeyi döner.
Map<String, dynamic> unwrapContentBody(dynamic body) {
  final map = asJsonMap(body);
  final data = map['data'];
  if (map['success'] == true && data is Map) return asJsonMap(data);
  return map;
}

String? _str(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

DateTime? _date(Map<String, dynamic> m, List<String> keys) {
  final raw = _str(m, keys);
  return raw == null ? null : DateTime.tryParse(raw);
}

/// Blog yazısı — liste satırı veya `GET /api/blog?slug=` detayı.
class BlogPostItem {
  const BlogPostItem({
    required this.id,
    required this.slug,
    required this.title,
    this.summary,
    this.content,
    this.coverImage,
    this.category,
    this.authorName,
    this.readTime = 0,
    this.views = 0,
    this.likes = 0,
    this.publishedAt,
  });

  factory BlogPostItem.fromJson(Map<String, dynamic> json) => BlogPostItem(
        id: _str(json, ['id']) ?? '',
        slug: _str(json, ['slug']) ?? '',
        title: _str(json, ['titleTr', 'title']) ?? '',
        summary: _str(json, ['descTr', 'summary', 'description']),
        content: _str(json, ['contentTr', 'content']),
        coverImage: _str(json, ['coverImage', 'imageUrl']),
        category: _str(json, ['category']),
        authorName: _str(json, ['authorName']),
        readTime: asInt(json['readTime']),
        views: asInt(json['views']),
        likes: asInt(json['likes']),
        publishedAt: _date(json, ['publishedAt', 'createdAt']),
      );

  final String id;
  final String slug;
  final String title;
  final String? summary;
  final String? content;
  final String? coverImage;
  final String? category;
  final String? authorName;
  final int readTime;
  final int views;
  final int likes;
  final DateTime? publishedAt;
}

/// `GET /api/blog/interactions?postId=` — oturumsuzsa hep false döner.
class BlogInteractions {
  const BlogInteractions({
    this.liked = false,
    this.favorited = false,
    this.likesCount = 0,
  });

  factory BlogInteractions.fromJson(Map<String, dynamic> json) =>
      BlogInteractions(
        liked: asBool(json['liked']),
        favorited: asBool(json['favorited']),
        likesCount: asInt(json['likesCount']),
      );

  final bool liked;
  final bool favorited;
  final int likesCount;
}

/// `GET /api/blog/zodiac` — burç başına yazı sayısı.
class ZodiacBlogSign {
  const ZodiacBlogSign({
    required this.sign,
    required this.totalPosts,
    this.latestTitle,
  });

  factory ZodiacBlogSign.fromJson(Map<String, dynamic> json) {
    final latest = json['latestPost'];
    return ZodiacBlogSign(
      sign: _str(json, ['sign']) ?? '',
      totalPosts: asInt(json['totalPosts']),
      latestTitle: latest is Map ? _str(asJsonMap(latest), ['titleTr']) : null,
    );
  }

  final String sign;
  final int totalPosts;
  final String? latestTitle;

  static const labels = {
    'koc': 'Koç',
    'boga': 'Boğa',
    'ikizler': 'İkizler',
    'yengec': 'Yengeç',
    'aslan': 'Aslan',
    'basak': 'Başak',
    'terazi': 'Terazi',
    'akrep': 'Akrep',
    'yay': 'Yay',
    'oglak': 'Oğlak',
    'kova': 'Kova',
    'balik': 'Balık',
  };

  String get label => labels[sign] ?? sign;
}

/// `GET /api/dream-symbols/{slug}`.
class DreamSymbolDetail {
  const DreamSymbolDetail({
    required this.name,
    required this.slug,
    required this.meaning,
    this.detailedMeaning,
    this.related = const [],
  });

  factory DreamSymbolDetail.fromJson(Map<String, dynamic> json) {
    final rel = asJsonList(json['relatedDreams'])
        .map((r) => (name: _str(r, ['name']) ?? '', slug: _str(r, ['slug']) ?? ''))
        .where((r) => r.name.isNotEmpty && r.slug.isNotEmpty)
        .toList();
    return DreamSymbolDetail(
      name: _str(json, ['name']) ?? '',
      slug: _str(json, ['slug']) ?? '',
      meaning: _str(json, ['meaning']) ?? '',
      detailedMeaning: _str(json, ['detailedMeaning']),
      related: rel,
    );
  }

  final String name;
  final String slug;
  final String meaning;
  final String? detailedMeaning;
  final List<({String name, String slug})> related;
}

/// `GET /api/tiktok-videos` satırı / `GET /api/tiktok-videos/{id}` videosu.
class TiktokVideoItem {
  const TiktokVideoItem({
    required this.id,
    required this.tiktokUrl,
    this.tiktokId,
    this.title,
    this.authorName,
    this.thumbnailUrl,
    this.categoryTitle,
  });

  factory TiktokVideoItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    return TiktokVideoItem(
      id: _str(json, ['id']) ?? '',
      tiktokUrl: _str(json, ['tiktokUrl']) ?? '',
      tiktokId: _str(json, ['tiktokId']),
      title: _str(json, ['title']),
      authorName: _str(json, ['authorName']),
      thumbnailUrl: _str(json, ['thumbnailUrl']),
      categoryTitle: cat is Map ? _str(asJsonMap(cat), ['title']) : null,
    );
  }

  final String id;
  final String tiktokUrl;
  final String? tiktokId;
  final String? title;
  final String? authorName;
  final String? thumbnailUrl;
  final String? categoryTitle;

  String get displayTitle =>
      (title?.isNotEmpty ?? false) ? title! : (authorName ?? 'TikTok videosu');

  /// Uygulama dışında açılacak adres — yalnız https TikTok bağlantısı.
  Uri? get externalUri {
    final uri = Uri.tryParse(tiktokUrl);
    if (uri == null || uri.scheme != 'https') return null;
    return uri;
  }
}

class TiktokVideoDetail {
  const TiktokVideoDetail({required this.video, this.related = const []});

  factory TiktokVideoDetail.fromJson(Map<String, dynamic> json) =>
      TiktokVideoDetail(
        video: TiktokVideoItem.fromJson(asJsonMap(json['video'])),
        related: asJsonList(json['related'])
            .map(TiktokVideoItem.fromJson)
            .where((v) => v.id.isNotEmpty)
            .toList(),
      );

  final TiktokVideoItem video;
  final List<TiktokVideoItem> related;
}
