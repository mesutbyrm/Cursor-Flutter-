import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_stream_entity.dart';

part 'live_stream_dto.freezed.dart';

/// API satırı — esnek alan adları `fromApiMap` ile çözülür.
@freezed
abstract class LiveStreamDto with _$LiveStreamDto {
  const factory LiveStreamDto({
    required String id,
    @Default('Canlı yayın') String title,
    String? streamerName,
    String? thumbnailUrl,
    @Default(0) int viewerCount,
    @Default(true) bool isLive,
    String? hostUserId,
  }) = _LiveStreamDto;

  const LiveStreamDto._();

  factory LiveStreamDto.fromApiMap(Map<String, dynamic> json) {
    final titleRaw = pick(json, ['title', 'name', 'description'])?.toString();
    final title = (titleRaw != null && titleRaw.trim().isNotEmpty)
        ? titleRaw.trim()
        : 'Canlı yayın';

    final status = pick(json, ['status'])?.toString().toLowerCase();
    final endedAt = pick(json, ['endedAt', 'ended_at']);
    final isLiveFlag = pick(json, ['isLive']);

    var isLive = true;
    if (isLiveFlag is bool) {
      isLive = isLiveFlag;
    } else if (status == 'ended' || status == 'offline' || endedAt != null) {
      isLive = false;
    }

    String? hostUserId;
    String? streamerName;
    final u = pick(json, ['user', 'streamer', 'host']);
    if (u is Map) {
      final m = asJsonMap(u);
      hostUserId = pick(m, ['id', 'userId'])?.toString();
      streamerName = pick(m, ['displayName', 'username', 'name'])?.toString();
    }
    streamerName ??=
        pick(json, ['streamerName', 'hostName', 'username'])?.toString();
    hostUserId ??= pick(json, ['userId', 'hostUserId', 'streamerId'])
        ?.toString();

    return LiveStreamDto(
      id: pick(json, ['id', '_id', 'streamId'])?.toString() ?? '',
      title: title,
      streamerName: streamerName,
      thumbnailUrl: pick(json, [
        'thumbnailUrl',
        'thumbnail',
        'coverUrl',
        'imageUrl',
        'broadcastImage',
        'backgroundUrl',
      ]) as String?,
      viewerCount: asInt(pick(json, ['viewerCount', 'viewers', 'watching'])),
      isLive: isLive,
      hostUserId: hostUserId,
    );
  }

  LiveStreamEntity toEntity() => LiveStreamEntity(
        id: id,
        title: title,
        streamerName: streamerName,
        thumbnailUrl: thumbnailUrl,
        viewerCount: viewerCount,
        isLive: isLive,
        hostUserId: hostUserId,
      );
}
