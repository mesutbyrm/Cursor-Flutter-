import 'package:flutter/material.dart';

import '../../../../core/offline/cache_first_loader.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_rooms_page.dart';
import '../../domain/repositories/voice_rooms_discover_repository.dart';
import '../../presentation/widgets/voice_rooms_ui/voice_rooms_mock_data.dart';
import '../datasources/voice_rooms_discover_remote_datasource.dart';
import '../mappers/voice_rooms_discover_mapper.dart';

class VoiceRoomsDiscoverRepositoryImpl implements VoiceRoomsDiscoverRepository {
  VoiceRoomsDiscoverRepositoryImpl(this._remote);

  final VoiceRoomsDiscoverRemoteDataSource _remote;
  static const _pageSize = 6;

  @override
  Future<VoiceRoomsDiscoverBundle> fetchDiscoverBundle({
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'voice_discover_bundle_v2_${categoryId ?? 'all'}';
    return CacheFirstLoader.load(
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
      maxAge: const Duration(minutes: 2),
      fetch: () async {
        final pageResult = await _remote.fetchVoiceRoomsPage(
          categoryId: categoryId,
          page: 1,
        );
        final rooms = pageResult.rooms;
        return VoiceRoomsDiscoverBundle(
          categories: VoiceRoomsDiscoverMapper.categoriesFromApi(),
          featured: VoiceRoomsDiscoverMapper.featuredFromRooms(rooms),
          popular: VoiceRoomsDiscoverMapper.popularFromRooms(rooms),
          allRooms: rooms,
          apiPage: pageResult.page,
          apiHasMore: pageResult.hasMore,
        );
      },
      encode: (b) => {
        'categories': b.categories
            .map(
              (c) => {
                'id': c.id,
                'label': c.label,
                'iconKey': c.iconKey,
                'colors': c.colors.map((e) => e.toARGB32()).toList(),
              },
            )
            .toList(),
        'featured': b.featured
            .map(
              (f) => {
                'id': f.id,
                'title': f.title,
                'subtitle': f.subtitle,
                'badge': f.badge,
                'iconKey': f.iconKey,
                'gradient': f.gradient.map((e) => e.toARGB32()).toList(),
                'glowColor': f.glowColor.toARGB32(),
              },
            )
            .toList(),
        'popular': b.popular
            .map(
              (p) => {
                'id': p.id,
                'rank': p.rank,
                'title': p.title,
                'description': p.description,
                'viewers': p.viewers,
                'tags': p.tags,
                'participantCount': p.participantCount,
                'themeColor': p.themeColor.toARGB32(),
                'iconKey': p.iconKey,
                'avatarColors':
                    p.avatarColors.map((e) => e.toARGB32()).toList(),
              },
            )
            .toList(),
        'rooms': b.allRooms.map(_encodeRoom).toList(),
        'apiPage': b.apiPage,
        'apiHasMore': b.apiHasMore,
      },
      decode: (json) {
        final rooms = _decodeRooms(json['rooms']);
        final apiPage = (json['apiPage'] as num?)?.toInt() ?? 1;
        final apiHasMore = json['apiHasMore'] == true;
        if (rooms.isEmpty) {
          return VoiceRoomsDiscoverBundle(
            categories: VoiceRoomsDiscoverMapper.categoriesFromApi(),
            featured: VoiceRoomsMockData.featured,
            popular: VoiceRoomsMockData.popularRooms,
            allRooms: const [],
            apiPage: apiPage,
            apiHasMore: apiHasMore,
          );
        }
        return VoiceRoomsDiscoverBundle(
          categories: _decodeCategories(json['categories']),
          featured: _decodeFeatured(json['featured'], rooms),
          popular: _decodePopular(json['popular'], rooms),
          allRooms: rooms,
          apiPage: apiPage,
          apiHasMore: apiHasMore,
        );
      },
    );
  }

  @override
  Future<VoiceRoomsPage> fetchRoomsPage({
    String? categoryId,
    required int page,
  }) {
    return _remote.fetchVoiceRoomsPage(categoryId: categoryId, page: page);
  }

  @override
  Future<List<TrendingTopicItem>> fetchTrends({bool forceRefresh = false}) {
    return CacheFirstLoader.load(
      cacheKey: 'voice_discover_trends',
      forceRefresh: forceRefresh,
      maxAge: const Duration(minutes: 10),
      fetch: () async {
        final raw = await _remote.fetchTrendTopics();
        return VoiceRoomsDiscoverMapper.trendsFromApi(raw);
      },
      encode: (items) => {
        'items': items
            .map((t) => {'tag': t.tag, 'views': t.views})
            .toList(),
      },
      decode: (json) {
        final raw = json['items'];
        if (raw is! List) return VoiceRoomsMockData.trendingTopics;
        final items = raw
            .whereType<Map>()
            .map(
              (m) => TrendingTopicItem(
                tag: '${m['tag']}',
                views: '${m['views']}',
              ),
            )
            .toList();
        return items.isEmpty ? VoiceRoomsMockData.trendingTopics : items;
      },
    );
  }

  @override
  Future<List<ActiveSpeakerItem>> fetchActiveSpeakers({
    bool forceRefresh = false,
  }) {
    return CacheFirstLoader.load(
      cacheKey: 'voice_discover_speakers',
      forceRefresh: forceRefresh,
      maxAge: const Duration(minutes: 5),
      fetch: () async {
        final entries = await _remote.fetchActiveSpeakers();
        return VoiceRoomsDiscoverMapper.speakersFromLeaderboard(entries);
      },
      encode: (items) => {
        'items': items
            .map(
              (s) => {
                'rank': s.rank,
                'name': s.name,
                'diamonds': s.diamonds,
                'avatarColor': s.avatarColor.toARGB32(),
              },
            )
            .toList(),
      },
      decode: (json) {
        final raw = json['items'];
        if (raw is! List) return VoiceRoomsMockData.activeSpeakers;
        final items = raw.whereType<Map>().map((m) {
          return ActiveSpeakerItem(
            rank: (m['rank'] as num?)?.toInt() ?? 0,
            name: '${m['name']}',
            diamonds: '${m['diamonds']}',
            avatarColor: Color((m['avatarColor'] as num?)?.toInt() ?? 0),
          );
        }).toList();
        return items.isEmpty ? VoiceRoomsMockData.activeSpeakers : items;
      },
    );
  }

  @override
  List<NearbyRoomItem> mapNearbyPage({
    required List<VoiceRoomEntity> rooms,
    required VoiceRoomsNearbyTab tab,
    required int page,
    int pageSize = _pageSize,
  }) {
    final all = VoiceRoomsDiscoverMapper.nearbyFromRooms(rooms, tab: tab);
    final end = (page + 1) * pageSize;
    if (end >= all.length) return all;
    return all.take(end).toList();
  }

  @override
  bool hasMoreNearby({
    required List<VoiceRoomEntity> rooms,
    required VoiceRoomsNearbyTab tab,
    required int loadedCount,
    int pageSize = _pageSize,
  }) {
    final total = VoiceRoomsDiscoverMapper.nearbyFromRooms(rooms, tab: tab).length;
    return loadedCount < total;
  }

  static Map<String, dynamic> _encodeRoom(VoiceRoomEntity r) => {
        'id': r.id,
        'slug': r.slug,
        'nameTr': r.nameTr,
        'descTr': r.descTr,
        'onlineCount': r.onlineCount,
        'userCount': r.userCount,
        'ownerName': r.ownerName,
        'ownerId': r.ownerId,
        'activeDjId': r.activeDjId,
        'djUserIds': r.djUserIds,
        'recentUserAvatars': r.recentUserAvatars,
        'isVip': r.isVip,
        'roomType': r.roomType,
        'isLocked': r.isLocked,
        'hasPassword': r.hasPassword,
        'category': r.category,
      };

  static List<VoiceRoomEntity> _decodeRooms(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      final dj = m['djUserIds'];
      final avatars = m['recentUserAvatars'];
      return VoiceRoomEntity(
        id: '${m['id']}',
        slug: '${m['slug'] ?? m['id']}',
        nameTr: '${m['nameTr'] ?? 'Sohbet Odası'}',
        descTr: m['descTr']?.toString(),
        onlineCount: (m['onlineCount'] as num?)?.toInt() ?? 0,
        userCount: (m['userCount'] as num?)?.toInt() ?? 0,
        ownerName: m['ownerName']?.toString(),
        ownerId: m['ownerId']?.toString(),
        activeDjId: m['activeDjId']?.toString(),
        djUserIds: dj is List ? dj.map((e) => '$e').toList() : const [],
        recentUserAvatars:
            avatars is List ? avatars.map((e) => '$e').toList() : const [],
        isVip: m['isVip'] as bool?,
        roomType: m['roomType']?.toString(),
        isLocked: m['isLocked'] as bool?,
        hasPassword: m['hasPassword'] as bool?,
        category: m['category']?.toString(),
      );
    }).toList();
  }

  static List<VoiceCategoryItem> _decodeCategories(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return VoiceRoomsDiscoverMapper.categoriesFromApi();
    }
    return raw.whereType<Map>().map((m) {
      final colors = m['colors'];
      return VoiceCategoryItem(
        id: '${m['id']}',
        label: '${m['label']}',
        iconKey: '${m['iconKey']}',
        colors: colors is List
            ? colors
                .map((c) => Color((c as num).toInt()))
                .toList()
            : VoiceRoomsMockData.categories.first.colors,
      );
    }).toList();
  }

  static List<FeaturedRoomItem> _decodeFeatured(
    dynamic raw,
    List<VoiceRoomEntity> rooms,
  ) {
    if (raw is! List || raw.isEmpty) {
      return VoiceRoomsDiscoverMapper.featuredFromRooms(rooms);
    }
    return raw.whereType<Map>().map((m) {
      final gradient = m['gradient'];
      return FeaturedRoomItem(
        id: '${m['id']}',
        title: '${m['title']}',
        subtitle: '${m['subtitle']}',
        badge: '${m['badge']}',
        iconKey: '${m['iconKey']}',
        gradient: gradient is List
            ? gradient.map((c) => Color((c as num).toInt())).toList()
            : VoiceRoomsMockData.featured.first.gradient,
        glowColor: Color((m['glowColor'] as num?)?.toInt() ?? 0),
      );
    }).toList();
  }

  static List<PopularRoomItem> _decodePopular(
    dynamic raw,
    List<VoiceRoomEntity> rooms,
  ) {
    if (raw is! List || raw.isEmpty) {
      return VoiceRoomsDiscoverMapper.popularFromRooms(rooms);
    }
    return raw.whereType<Map>().map((m) {
      final avatarColors = m['avatarColors'];
      final tags = m['tags'];
      return PopularRoomItem(
        id: '${m['id']}',
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        title: '${m['title']}',
        description: '${m['description']}',
        viewers: '${m['viewers']}',
        tags: tags is List ? tags.map((e) => '$e').toList() : const [],
        participantCount: (m['participantCount'] as num?)?.toInt() ?? 0,
        themeColor: Color((m['themeColor'] as num?)?.toInt() ?? 0),
        iconKey: '${m['iconKey']}',
        avatarColors: avatarColors is List
            ? avatarColors.map((c) => Color((c as num).toInt())).toList()
            : const [],
      );
    }).toList();
  }
}
