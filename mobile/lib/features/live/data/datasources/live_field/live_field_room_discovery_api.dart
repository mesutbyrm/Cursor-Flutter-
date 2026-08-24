import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/util/json_util.dart';
import 'live_field_api_util.dart';

/// Saha 2 — Oda keşif & listeleme (`GET /api/live/rooms`).
class LiveFieldRoomDiscoveryApi {
  LiveFieldRoomDiscoveryApi(this._dio);

  final Dio _dio;

  Future<LiveFieldRoomsPage> fetchRooms({
    String type = 'all',
    int page = 1,
    int limit = 30,
    String? search,
    String? category,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveRooms,
      query: {
        'type': type,
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim().toLowerCase(),
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      return const LiveFieldRoomsPage(rooms: []);
    }
    final rooms = LiveFieldApiUtil.listFromData(map, listKey: 'rooms')
        .map(LiveFieldRoomSummary.fromJson)
        .toList(growable: false);
    final pagination = asJsonMap(map['pagination']);
    return LiveFieldRoomsPage(
      rooms: rooms,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      limit: (pagination['limit'] as num?)?.toInt() ?? limit,
      total: (pagination['total'] as num?)?.toInt(),
    );
  }
}

class LiveFieldRoomsPage {
  const LiveFieldRoomsPage({
    required this.rooms,
    this.page = 1,
    this.limit = 30,
    this.total,
  });

  final List<LiveFieldRoomSummary> rooms;
  final int page;
  final int limit;
  final int? total;
}

class LiveFieldRoomSummary {
  const LiveFieldRoomSummary({
    required this.id,
    required this.roomType,
    this.title,
    this.slug,
    this.hostId,
    this.hostName,
    this.hostImage,
    this.thumbnailUrl,
    this.backgroundImage,
    this.viewerCount = 0,
    this.likeCount = 0,
    this.isLive = false,
    this.isPkLive = false,
    this.musicPlaying = false,
  });

  final String id;
  final String roomType;
  final String? title;
  final String? slug;
  final String? hostId;
  final String? hostName;
  final String? hostImage;
  final String? thumbnailUrl;
  final String? backgroundImage;
  final int viewerCount;
  final int likeCount;
  final bool isLive;
  final bool isPkLive;
  final bool musicPlaying;

  bool get isVoice => roomType.toLowerCase() == 'voice';
  bool get isStream => roomType.toLowerCase() == 'stream';

  factory LiveFieldRoomSummary.fromJson(Map<String, dynamic> json) {
    return LiveFieldRoomSummary(
      id: json['id']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? 'voice',
      title: json['title']?.toString() ?? json['nameTr']?.toString(),
      slug: json['slug']?.toString(),
      hostId: json['hostId']?.toString() ?? json['ownerId']?.toString(),
      hostName: json['hostName']?.toString(),
      hostImage: json['hostImage']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      backgroundImage: json['backgroundImage']?.toString(),
      viewerCount: (json['viewerCount'] as num?)?.toInt() ??
          (json['onlineCount'] as num?)?.toInt() ??
          (json['userCount'] as num?)?.toInt() ??
          0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLive: json['isLive'] == true || json['status']?.toString() == 'live',
      isPkLive: json['isPkLive'] == true ||
          json['pkActive'] == true ||
          json['inPk'] == true,
      musicPlaying: json['musicPlaying'] == true ||
          json['isMusicPlaying'] == true ||
          json['djPlaying'] == true,
    );
  }
}
