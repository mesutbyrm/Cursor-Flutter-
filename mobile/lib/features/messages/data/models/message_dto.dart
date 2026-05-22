import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';

part 'message_dto.freezed.dart';

@freezed
abstract class MessageDto with _$MessageDto {
  const factory MessageDto({
    required String id,
    @Default('') String text,
    @Default(false) bool isMine,
    DateTime? createdAt,
    @Default(MessageDeliveryStatus.sent) MessageDeliveryStatus deliveryStatus,
  }) = _MessageDto;

  const MessageDto._();

  factory MessageDto.fromApiMap(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final readAt = pick(json, ['readAt', 'read_at', 'seenAt']);
    final deliveredAt = pick(json, ['deliveredAt', 'delivered_at']);
    final statusRaw = pick(json, ['status', 'deliveryStatus'])?.toString();
    final senderId = pick(json, [
      'senderId',
      'sender_id',
      'fromUserId',
      'fromId',
      'userId',
    ])?.toString();

    var delivery = MessageDeliveryStatus.sent;
    if (readAt != null || statusRaw == 'read') {
      delivery = MessageDeliveryStatus.read;
    } else if (deliveredAt != null || statusRaw == 'delivered') {
      delivery = MessageDeliveryStatus.delivered;
    }

    var isMine = asBool(pick(json, ['isMine', 'mine', 'fromMe', 'is_mine']));
    if (!isMine &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId != null &&
        senderId.isNotEmpty) {
      isMine = senderId == currentUserId;
    }

    return MessageDto(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      text: pick(json, ['text', 'body', 'content'])?.toString() ?? '',
      isMine: isMine,
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ?? '',
      ),
      deliveryStatus: delivery,
    );
  }

  MessageEntity toEntity() => MessageEntity(
        id: id,
        text: text,
        isMine: isMine,
        createdAt: createdAt,
        deliveryStatus: deliveryStatus,
      );
}
