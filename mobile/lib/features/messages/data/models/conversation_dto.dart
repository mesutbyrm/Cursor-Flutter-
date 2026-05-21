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
    final peer = pick(json, ['peer', 'user', 'participant']);
    final peerMap = peer is Map ? asJsonMap(peer) : <String, dynamic>{};

    return ConversationDto(
      id: pick(json, ['id', '_id', 'conversationId'])?.toString() ?? '',
      title: pick(json, ['title', 'name'])?.toString() ??
          pick(peerMap, ['displayName', 'username'])?.toString() ??
          'Sohbet',
      subtitle:
          pick(json, ['lastMessage', 'preview', 'subtitle'])?.toString(),
      avatarUrl: pick(peerMap, ['avatarUrl', 'avatar_url', 'photoUrl'])
          as String?,
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
