import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';

class MessageDto {
  const MessageDto({
    required this.id,
    this.text = '',
    this.isMine = false,
    this.createdAt,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.replyTo,
    this.forwardedFrom,
    this.rawText,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime? createdAt;
  final MessageDeliveryStatus deliveryStatus;
  final DmReplyMeta? replyTo;
  final String? forwardedFrom;
  final String? rawText;

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

    var isMine = asBool(pick(json, ['isMine', 'mine', 'fromMe', 'is_mine']));
    if (!isMine &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId != null &&
        senderId.isNotEmpty) {
      isMine = senderId == currentUserId;
    }

    var delivery = MessageDeliveryStatus.sent;
    final readFlag = asBool(pick(json, ['read', 'isRead', 'seen']));
    if (readAt != null || readFlag || statusRaw == 'read') {
      delivery = MessageDeliveryStatus.read;
    } else if (deliveredAt != null || statusRaw == 'delivered') {
      delivery = MessageDeliveryStatus.delivered;
    } else if (isMine && readFlag == false) {
      delivery = MessageDeliveryStatus.delivered;
    }

    final rawText = pick(json, ['text', 'body', 'content'])?.toString() ?? '';
    final parsed = DmMessageCodec.parseDisplay(rawText);

    return MessageDto(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      text: parsed.displayText,
      isMine: isMine,
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ?? '',
      ),
      deliveryStatus: delivery,
      replyTo: parsed.reply,
      forwardedFrom: parsed.forwardedFrom,
      rawText: rawText,
    );
  }

  MessageEntity toEntity() => MessageEntity(
        id: id,
        text: text,
        isMine: isMine,
        createdAt: createdAt,
        deliveryStatus: deliveryStatus,
        replyTo: replyTo,
        forwardedFrom: forwardedFrom,
        rawText: rawText,
      );
}
