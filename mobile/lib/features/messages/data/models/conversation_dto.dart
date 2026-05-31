import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';

part 'conversation_dto.freezed.dart';

@freezed
abstract class ConversationDto with _$ConversationDto {
  const factory ConversationDto({
    required String id,
    @Default('Sohbet') String title,
    String? subtitle,
    String? avatarUrl,
    @Default(0) int unreadCount,
    @Default(false) bool isOnline,
  }) = _ConversationDto;

  const ConversationDto._();

  factory ConversationDto.fromApiMap(Map<String, dynamic> json) {
    final peer = pick(json, ['otherUser', 'peer', 'user', 'participant']);
    final peerMap = peer is Map ? asJsonMap(peer) : <String, dynamic>{};
    final peerId = pick(peerMap, ['id', 'userId'])?.toString() ?? '';

    var subtitle = pick(json, ['lastMessage', 'preview', 'subtitle'])?.toString();
    final lastMsg = pick(json, ['lastMessage']);
    if (lastMsg is Map) {
      subtitle = pick(asJsonMap(lastMsg), ['content', 'text'])?.toString() ??
          subtitle;
    }

    return ConversationDto(
      id: peerId.isNotEmpty
          ? peerId
          : pick(json, ['id', '_id', 'conversationId'])?.toString() ?? '',
      title: pick(peerMap, ['name', 'displayName', 'username'])?.toString() ??
          pick(json, ['title', 'name'])?.toString() ??
          'Sohbet',
      subtitle: subtitle,
      avatarUrl: pick(peerMap, [
        'image',
        'avatarUrl',
        'avatar_url',
        'photoUrl',
      ]) as String?,
      unreadCount: asInt(pick(json, ['unreadCount', 'unread', 'badge'])),
      isOnline: asBool(pick(json, ['isOnline', 'online', 'is_online'])),
    );
  }

  ConversationEntity toEntity() => ConversationEntity(
        id: id,
        title: title,
        subtitle: subtitle,
        avatarUrl: avatarUrl,
        unreadCount: unreadCount,
        isOnline: isOnline,
      );
}
