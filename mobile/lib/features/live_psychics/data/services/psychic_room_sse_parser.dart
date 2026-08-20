import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import '../../domain/session_room_sse_event.dart';
import '../models/psychic_model.dart';

/// Seans oda SSE bloğu — test edilebilir ayrıştırma.
sealed class PsychicRoomSseEvent {
  const PsychicRoomSseEvent();
}

class PsychicRoomSseConnected extends PsychicRoomSseEvent {
  const PsychicRoomSseConnected(this.room);

  final PsychicRoomEntity room;
}

class PsychicRoomSseRoomUpdate extends PsychicRoomSseEvent {
  const PsychicRoomSseRoomUpdate(this.room);

  final PsychicRoomEntity room;
}

class PsychicRoomSseSessionEnded extends PsychicRoomSseEvent {
  const PsychicRoomSseSessionEnded(this.status);

  final PsychicSessionStatus status;
}

class PsychicRoomSseMessage extends PsychicRoomSseEvent {
  const PsychicRoomSseMessage(this.message);

  final PsychicChatMessage message;
}

class PsychicRoomSseTip extends PsychicRoomSseEvent {
  const PsychicRoomSseTip({required this.amount, this.fromName});

  final int amount;
  final String? fromName;
}

PsychicRoomSseEvent? parseSessionRoomSsePayload(
  Map<String, dynamic> map, {
  String? eventName,
  required String sessionId,
  String? myUserId,
}) {
  final type = inferSessionRoomSseEventType(map, eventName: eventName) ?? '';
  if (type == 'connected') {
    return PsychicRoomSseConnected(
      PsychicModel.roomFromJson(map, fallbackId: sessionId),
    );
  }
  if (type == 'ended' ||
      type == 'session_ended' ||
      type == 'session_end' ||
      type == 'expired' ||
      type == 'session_expired' ||
      type == 'cancelled' ||
      type == 'session_cancelled' ||
      type == 'rejected') {
    return PsychicRoomSseSessionEnded(
      type.contains('cancel') || type == 'rejected'
          ? PsychicSessionStatus.cancelled
          : type.contains('expir')
              ? PsychicSessionStatus.expired
              : PsychicSessionStatus.ended,
    );
  }
  if (type == 'tip' ||
      type == 'tip_received' ||
      type == 'bahsis' ||
      type == 'tip_sent' ||
      type == 'gift' ||
      type == 'gift_received' ||
      type == 'gift_sent' ||
      type == 'hediye' ||
      type.contains('gift') ||
      type.contains('hediye') ||
      (eventName?.toLowerCase().contains('gift') ?? false) ||
      (eventName?.toLowerCase().contains('tip') ?? false)) {
    final amount = _parseTipAmount(map);
    if (amount <= 0) return null;
    return PsychicRoomSseTip(
      amount: amount,
      fromName: map['senderName']?.toString() ??
          map['clientName']?.toString() ??
          map['fromName']?.toString(),
    );
  }
  if (type == 'timer_started' || type == 'time_extended') {
    return PsychicRoomSseRoomUpdate(
      PsychicModel.roomFromJson(
        map['room'] is Map
            ? Map<String, dynamic>.from(map['room'] as Map)
            : map,
        fallbackId: sessionId,
      ),
    );
  }
  final msg = PsychicModel.chatFromJson(map, myUserId: myUserId);
  if (msg.text.trim().isNotEmpty) {
    return PsychicRoomSseMessage(msg);
  }
  final room = PsychicModel.roomFromJson(
    map['room'] is Map
        ? Map<String, dynamic>.from(map['room'] as Map)
        : map,
    fallbackId: sessionId,
  );
  if (room.status == PsychicSessionStatus.cancelled ||
      room.status == PsychicSessionStatus.rejected ||
      room.status == PsychicSessionStatus.ended ||
      room.status == PsychicSessionStatus.expired) {
    return PsychicRoomSseSessionEnded(room.status);
  }
  return PsychicRoomSseRoomUpdate(room);
}

int _parseTipAmount(Map<String, dynamic> map) {
  final raw = map['amount'] ??
      map['jeton'] ??
      map['tipAmount'] ??
      map['giftValue'] ??
      map['coins'] ??
      map['coin'] ??
      map['price'] ??
      map['value'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
