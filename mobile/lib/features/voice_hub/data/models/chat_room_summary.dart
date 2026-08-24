import '../../../../core/util/json_util.dart';

/// `GET /api/chat/rooms` oda kartı.
class ChatRoomSummary {
  const ChatRoomSummary({
    required this.id,
    required this.name,
    this.slug,
    this.type,
    this.category,
    this.memberCount = 0,
    this.isLive = false,
    this.imageUrl,
    this.ownerName,
    this.raw = const {},
  });

  final String id;
  final String name;
  final String? slug;
  final String? type;
  final String? category;
  final int memberCount;
  final bool isLive;
  final String? imageUrl;
  final String? ownerName;
  final Map<String, dynamic> raw;

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) {
    final id = pick(json, [
      'id',
      'roomId',
      '_id',
      'apiRoomKey',
      'slug',
    ])?.toString() ??
        '';
    return ChatRoomSummary(
      id: id,
      name: pick(json, ['name', 'title', 'roomName'])?.toString() ?? 'Oda',
      slug: pick(json, ['slug', 'roomSlug'])?.toString(),
      type: pick(json, ['type', 'roomType'])?.toString(),
      category: pick(json, ['category', 'subcategory'])?.toString(),
      memberCount: asInt(
        pick(json, [
          'memberCount',
          'userCount',
          'onlineCount',
          'listeners',
          'viewerCount',
        ]),
      ),
      isLive: json['isLive'] == true ||
          json['live'] == true ||
          json['isActive'] == true,
      imageUrl: pick(json, [
        'image',
        'imageUrl',
        'coverImage',
        'background',
        'thumbnail',
      ])?.toString(),
      ownerName: pick(json, ['ownerName', 'hostName'])?.toString(),
      raw: json,
    );
  }
}
