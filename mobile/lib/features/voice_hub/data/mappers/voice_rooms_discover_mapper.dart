import 'package:flutter/material.dart';

import '../../../../core/util/json_util.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_room_sort.dart';
import '../../domain/repositories/voice_rooms_discover_repository.dart';
import '../../presentation/widgets/voice_rooms_ui/voice_rooms_mock_data.dart';
import '../../presentation/widgets/voice_rooms_ui/voice_rooms_ui_tokens.dart';

abstract final class VoiceRoomsDiscoverMapper {
  static const _themePalette = [
    VoiceRoomsUiTokens.purpleGlow,
    VoiceRoomsUiTokens.teal,
    VoiceRoomsUiTokens.coral,
    VoiceRoomsUiTokens.orange,
    VoiceRoomsUiTokens.blue,
    VoiceRoomsUiTokens.magenta,
  ];

  static List<VoiceCategoryItem> categoriesFromApi({
    List<VoiceCategoryItem> catalog = VoiceRoomsMockData.categories,
  }) {
    return catalog
        .map(
          (c) => VoiceCategoryItem(
            id: c.id,
            label: c.label,
            iconKey: c.iconKey,
            colors: c.colors,
          ),
        )
        .toList();
  }

  static List<FeaturedRoomItem> featuredFromRooms(List<VoiceRoomEntity> rooms) {
    final sorted = sortVoiceRoomsByPopularity(rooms);
    final picks = sorted.take(2).toList();
    if (picks.isEmpty) return const [];

    final gradients = [
      [const Color(0xFF7B2FF7), const Color(0xFF4A00E0)],
      [const Color(0xFF448AFF), const Color(0xFF7C4DFF)],
    ];
    final glows = [VoiceRoomsUiTokens.purpleGlow, VoiceRoomsUiTokens.blue];
    final icons = ['mic', 'headphones'];

    return List.generate(picks.length, (i) {
      final r = picks[i];
      final hasDj = r.activeDjId != null || r.djUserIds.isNotEmpty;
      return FeaturedRoomItem(
        id: r.id,
        title: r.displayTitle,
        subtitle: r.descTr?.trim().isNotEmpty == true
            ? r.descTr!.trim()
            : '${r.displayOnline} dinleyici',
        badge: i == 0 ? 'Günün Öne Çıkan Odası' : 'Canlı DJ',
        iconKey: hasDj ? icons[1] : icons[0],
        gradient: gradients[i % gradients.length],
        glowColor: glows[i % glows.length],
      );
    });
  }

  static List<PopularRoomItem> popularFromRooms(List<VoiceRoomEntity> rooms) {
    final live = rooms.where((r) => r.displayOnline > 0).toList();
    if (live.isEmpty) return const [];

    final sorted = sortVoiceRoomsByPopularity(live);
    final picks = sorted.take(4).toList();

    return List.generate(picks.length, (i) {
      final r = picks[i];
      final theme = _themePalette[i % _themePalette.length];
      return PopularRoomItem(
        id: r.id,
        rank: i + 1,
        title: r.displayTitle,
        description: r.descTr?.trim().isNotEmpty == true
            ? r.descTr!.trim()
            : 'Canlı sesli sohbet',
        viewers: _formatCount(r.displayOnline),
        tags: _tagsFor(r),
        participantCount: r.userCount > 0 ? r.userCount : r.displayOnline,
        themeColor: theme,
        iconKey: _iconKeyFor(r),
        avatarColors: _avatarColors(r, theme),
      );
    });
  }

  static List<NearbyRoomItem> nearbyFromRooms(
    List<VoiceRoomEntity> rooms, {
    required VoiceRoomsNearbyTab tab,
  }) {
    final copy = List<VoiceRoomEntity>.from(rooms);
    switch (tab) {
      case VoiceRoomsNearbyTab.nearby:
        copy.sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
      case VoiceRoomsNearbyTab.newest:
        copy.sort((a, b) => b.id.compareTo(a.id));
      case VoiceRoomsNearbyTab.friends:
        copy.retainWhere((r) => r.recentUserAvatars.length >= 2);
        copy.sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
    }

    return copy.map((r) {
      final theme = _themePalette[r.id.hashCode.abs() % _themePalette.length];
      return NearbyRoomItem(
        id: r.id,
        title: r.displayTitle,
        subtitle: r.descTr?.trim().isNotEmpty == true
            ? r.descTr!.trim()
            : r.ownerName ?? 'Sesli oda',
        tags: _tagsFor(r),
        distance: _pseudoDistance(r),
        viewers: _formatCount(r.displayOnline),
        ringColor: r.displayOnline > 0
            ? VoiceRoomsUiTokens.onlineGreen
            : VoiceRoomsUiTokens.textMuted,
        avatarColor: theme,
        avatarUrl: r.ownerAvatarUrl ?? r.backgroundImageUrl,
      );
    }).toList();
  }

  static List<TrendingTopicItem> trendsFromApi(
    List<Map<String, dynamic>> raw,
  ) {
    if (raw.isEmpty) return const [];
    return raw.take(5).map((m) {
      final tag = (pick(m, ['tag', 'name', 'hashtag', 'title']) ?? '#Trend')
          .toString()
          .trim();
      final viewsRaw = pick(m, ['views', 'count', 'videoCount', 'score']);
      return TrendingTopicItem(
        tag: tag.startsWith('#') ? tag : '#$tag',
        views: _formatCount(asInt(viewsRaw)),
      );
    }).toList();
  }

  static List<ActiveSpeakerItem> speakersFromRooms(List<VoiceRoomEntity> rooms) {
    final candidates = <({String name, int online, String? avatarUrl})>[];
    for (final r in rooms) {
      if (r.displayOnline <= 0) continue;
      final owner = r.ownerName?.trim();
      if (owner != null && owner.isNotEmpty) {
        candidates.add((
          name: owner,
          online: r.displayOnline,
          avatarUrl: r.ownerAvatarUrl,
        ));
      }
    }
    if (candidates.isEmpty) return const [];

    candidates.sort((a, b) => b.online.compareTo(a.online));
    final colors = [
      VoiceRoomsUiTokens.gold,
      VoiceRoomsUiTokens.silver,
      VoiceRoomsUiTokens.bronze,
    ];
    return candidates.take(3).toList().asMap().entries.map((e) {
      final rank = e.key + 1;
      final c = e.value;
      return ActiveSpeakerItem(
        rank: rank,
        name: c.name,
        diamonds: _formatCount(c.online),
        avatarColor: colors[e.key % colors.length],
        avatarUrl: c.avatarUrl,
        onlineLabel: '${_formatCount(c.online)} dinleyici',
      );
    }).toList();
  }

  static List<ActiveSpeakerItem> speakersFromLeaderboard(
    List<GiftLeaderboardEntry> entries,
  ) {
    if (entries.isEmpty) return const [];
    final colors = [
      VoiceRoomsUiTokens.gold,
      VoiceRoomsUiTokens.blue,
      VoiceRoomsUiTokens.magenta,
    ];
    return entries.take(3).toList().asMap().entries.map((e) {
      final rank = e.key + 1;
      final entry = e.value;
      return ActiveSpeakerItem(
        rank: rank,
        name: entry.displayName,
        diamonds: _formatCount(entry.totalCoins),
        avatarColor: colors[e.key % colors.length],
      );
    }).toList();
  }

  static List<String> _tagsFor(VoiceRoomEntity r) {
    final tags = <String>[];
    if (r.isVip == true) tags.add('VIP');
    if (r.activeDjId != null || r.djUserIds.isNotEmpty) tags.add('Müzik');
    if (r.roomType != null && r.roomType!.isNotEmpty) {
      tags.add(r.roomType!);
    }
    if (tags.isEmpty) tags.add('Sohbet');
    return tags.take(2).toList();
  }

  static String _iconKeyFor(VoiceRoomEntity r) {
    final hay = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
    if (r.activeDjId != null || r.djUserIds.isNotEmpty) return 'music';
    if (hay.contains('aşk') || hay.contains('flört')) return 'heart';
    if (hay.contains('oyun')) return 'game';
    return 'mic';
  }

  static List<Color> _avatarColors(VoiceRoomEntity r, Color fallback) {
    if (r.recentUserAvatars.isNotEmpty) {
      return List.generate(
        3,
        (i) => _themePalette[(r.id.hashCode + i) % _themePalette.length],
      );
    }
    return [
      fallback,
      fallback.withValues(alpha: 0.8),
      fallback.withValues(alpha: 0.6),
    ];
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _pseudoDistance(VoiceRoomEntity r) {
    final bucket = r.id.hashCode.abs() % 30;
    final km = (bucket + 1) / 10.0;
    return '${km.toStringAsFixed(1)} km';
  }
}
