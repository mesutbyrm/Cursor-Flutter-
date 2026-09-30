import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../models/conversation_dto.dart';
import '../models/message_dto.dart';

class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ConversationEntity>> conversations({
    bool forceRefresh = false,
  }) async {
    final paths = Env.useMobileAuth
        ? [ApiEndpoints.messages, ApiEndpoints.messagesConversations]
        : [ApiEndpoints.messagesConversations, ApiEndpoints.messages];
    for (final path in paths) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          forceRefresh: forceRefresh,
        );
        final parsed = _parseConversations(res.data);
        if (parsed != null && parsed.isNotEmpty) return parsed;
        if (parsed != null) return parsed;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          throw const ApiException(
            'Mesajlar için oturum açmanız gerekiyor.',
            statusCode: 401,
          );
        }
      } catch (_) {}
    }
    return const [];
  }

  List<ConversationEntity>? _parseConversations(dynamic body) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }
    if (body is! Map && body is! List) return null;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) return null;

      if (map['success'] == true && map['data'] != null) {
        return _parseConversations(map['data']);
      }

      final list = pick(map, ['conversations', 'items', 'data', 'results']);
      if (list != null) {
        final parsed = asJsonList(list)
            .map(ConversationDto.fromApiMap)
            .map((d) => d.toEntity())
            .where((c) => c.id.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }

      // canlifal.com: { conversations: [...], requests: [...] } — boş liste de geçerli.
      final convOnly = map['conversations'];
      if (convOnly is List) {
        return asJsonList(convOnly)
            .map(ConversationDto.fromApiMap)
            .map((d) => d.toEntity())
            .where((c) => c.id.isNotEmpty)
            .toList();
      }
    }

    if (body is List) {
      return asJsonList(body)
          .map(ConversationDto.fromApiMap)
          .map((d) => d.toEntity())
          .where((c) => c.id.isNotEmpty)
          .toList();
    }
    return null;
  }

  Future<List<MessageEntity>> messages(
    String peerUserId, {
    String? currentUserId,
    bool forceRefresh = false,
  }) async {
    try {
      final path = Env.useMobileAuth
          ? ApiEndpoints.messagesWithUser(peerUserId)
          : ApiEndpoints.conversationMessages(peerUserId);
      final res = await _dio.safeGet<dynamic>(path, forceRefresh: forceRefresh);
      final parsed = _parseMessages(res.data, currentUserId: currentUserId);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Sohbet için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  List<MessageEntity>? _parseMessages(dynamic body, {String? currentUserId}) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }
    if (body is! Map && body is! List) return null;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) return null;

      if (map['success'] == true && map['data'] != null) {
        return _parseMessages(map['data'], currentUserId: currentUserId);
      }

      final list = pick(map, ['items', 'data', 'messages', 'results']);
      if (list != null) {
        return asJsonList(list)
            .map((j) => MessageDto.fromApiMap(j, currentUserId: currentUserId))
            .map((d) => d.toEntity())
            .where((m) => !DmMessageCodec.isSystemPayload(m.rawText ?? m.text))
            .toList();
      }
    }

    if (body is List) {
      return asJsonList(body)
          .map((j) => MessageDto.fromApiMap(j, currentUserId: currentUserId))
          .map((d) => d.toEntity())
          .where((m) => !DmMessageCodec.isSystemPayload(m.rawText ?? m.text))
          .toList();
    }
    return null;
  }

  Future<void> send(
    String peerUserId,
    String text, {
    String? replyId,
    String? replyText,
    bool forward = false,
    String? forwardFrom,
  }) async {
    var payload = text;
    if (replyId != null && replyText != null) {
      payload = DmMessageCodec.wrapReply(
        replyId: replyId,
        replyText: replyText,
        body: text,
      );
    } else if (forward) {
      payload = DmMessageCodec.wrapForward(
        body: text,
        fromLabel: forwardFrom ?? 'İletilen mesaj',
      );
    }
    try {
      if (Env.useMobileAuth) {
        await _dio.safePost(
          ApiEndpoints.messagesWithUser(peerUserId),
          data: {
            'content': payload,
            'message': payload,
            'text': payload,
          },
        );
        return;
      }
      await _dio.safePost(
        ApiEndpoints.conversationMessages(peerUserId),
        data: {
          'text': payload,
          'content': payload,
          'message': payload,
        },
      );
    } on ApiException catch (e) {
      // Gizlilik ayarı nedeniyle doğrudan mesaj kapalıysa sunucu 403 +
      // "Message request required" dönüyor. İstek hiç oluşturulmadığı için
      // mesaj karşı tarafa hiç ulaşmıyordu; burada otomatik istek gönderilir.
      if (e.statusCode == 403 && _needsMessageRequest(e.message)) {
        await sendMessageRequest(peerUserId, message: text);
        throw const ApiException(
          'Bu kişiye doğrudan mesaj gönderilemiyor. Mesaj isteğin iletildi; '
          'kabul edildiğinde yazabilirsin.',
          statusCode: 403,
        );
      }
      rethrow;
    }
  }

  static bool _needsMessageRequest(String message) {
    final m = message.toLowerCase();
    return m.contains('message request') ||
        m.contains('mesaj iste') ||
        m.contains('istek gerek');
  }

  // --- Mesaj istekleri ---

  /// Bekleyen gelen mesaj istekleri — `GET /api/messages` → `requests`.
  Future<List<MessageRequestEntity>> pendingMessageRequests({
    bool forceRefresh = true,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.messages,
        forceRefresh: forceRefresh,
      );
      var body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        body = body['data'];
      }
      if (body is! Map) return const [];
      final raw = asJsonMap(body)['requests'];
      if (raw is! List) return const [];
      final out = <MessageRequestEntity>[];
      for (final item in asJsonList(raw)) {
        final id = (item['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final sender = item['sender'] is Map
            ? asJsonMap(item['sender'])
            : <String, dynamic>{};
        final senderId = (sender['id'] ?? item['senderId'] ?? '').toString();
        if (senderId.isEmpty) continue;
        final name = (sender['name'] ?? sender['username'] ?? 'Kullanıcı')
            .toString();
        out.add(
          MessageRequestEntity(
            id: id,
            senderId: senderId,
            senderName: name.isEmpty ? 'Kullanıcı' : name,
            senderUsername: sender['username']?.toString(),
            senderImage: sender['image']?.toString(),
            message: item['message']?.toString(),
            createdAt: DateTime.tryParse(
              (item['createdAt'] ?? '').toString(),
            )?.toLocal(),
          ),
        );
      }
      return out;
    } on ApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Mesaj isteği oluştur — `POST /api/messages/request`.
  /// Zaten bekleyen bir istek varsa sunucu 400 döner; bu durum başarı sayılır.
  Future<void> sendMessageRequest(String receiverId, {String? message}) async {
    final id = receiverId.trim();
    if (id.isEmpty) return;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.messagesRequest,
        data: {
          'receiverId': id,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 400) return; // zaten bekliyor / işlenmiş
      rethrow;
    }
  }

  /// İsteği kabul et veya reddet — `PATCH /api/messages/request`.
  Future<void> respondMessageRequest(
    String requestId, {
    required bool accept,
  }) async {
    final id = requestId.trim();
    if (id.isEmpty) return;
    await _dio.safePatch<dynamic>(
      ApiEndpoints.messagesRequest,
      data: {'requestId': id, 'action': accept ? 'accept' : 'reject'},
    );
  }

  Future<void> blockUser(String blockedUserId) =>
      _setBlocked(blockedUserId, blocked: true);

  Future<void> unblockUser(String blockedUserId) =>
      _setBlocked(blockedUserId, blocked: false);

  /// `POST /api/user/block {userId}` aç/kapa çalışır → `{blocked}`; istenen
  /// duruma ulaşılmadıysa bir kez daha çağrılır.
  Future<void> _setBlocked(String userId, {required bool blocked}) async {
    for (var i = 0; i < 2; i++) {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.userBlock,
        data: {'userId': userId},
      );
      final now = asJsonMap(res.data)['blocked'];
      if (now is! bool || now == blocked) return;
    }
  }

  /// "Yazıyor" işareti gönderir ve karşı tarafın yazıp yazmadığını döndürür.
  /// [selfTyping] false ise yalnızca peerTyping okunur (kendi yazma işaretlenmez).
  Future<bool> pingTyping(
    String conversationId, {
    bool selfTyping = true,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.conversationTyping(conversationId),
        data: {'typing': selfTyping},
      );
      final data = res.data;
      if (data is Map) return data['peerTyping'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteMessage(String peerUserId, String messageId) async {
    if (messageId.isEmpty) return;
    try {
      // Backend tek ucu: `DELETE /api/messages/{userId}/{messageId}`.
      await _dio.safeDelete(ApiEndpoints.messageWithId(peerUserId, messageId));
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501) {
        return;
      }
      rethrow;
    }
  }

  /// Profilden sohbet — mobil API doğrudan userId ile çalışır.
  /// Okunmamış DM'leri sunucuda sıfırlar — backend'de toplu "okundu" ucu yok
  /// (`/api/messages` yalnız GET); `GET /api/messages/{userId}` okundu işaretler.
  Future<void> markAllConversationsRead() async {
    final convs = await conversations(forceRefresh: true);
    final peers = convs
        .where((c) => c.unreadCount > 0 && c.id.trim().isNotEmpty)
        .map((c) => c.id.trim())
        .toList();
    for (final peerId in peers) {
      try {
        await _dio.safeGet<dynamic>(
          ApiEndpoints.messagesWithUser(peerId),
          query: const {'limit': '1'},
        );
      } catch (_) {
        try {
          await _dio.safeGet<dynamic>(ApiEndpoints.messagesWithUser(peerId));
        } catch (_) {}
      }
    }
  }

  Future<ConversationEntity> startConversation(String recipientId) async {
    if (Env.useMobileAuth) {
      return ConversationEntity(id: recipientId, title: 'Sohbet');
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.messagesConversations,
      data: {'recipientId': recipientId},
    );
    final body = res.data;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['success'] == true && map['data'] is Map) {
        final dto = ConversationDto.fromApiMap(asJsonMap(map['data']));
        if (dto.id.isNotEmpty) return dto.toEntity();
      }
      final dto = ConversationDto.fromApiMap(map);
      if (dto.id.isNotEmpty) return dto.toEntity();
    }
    throw const ApiException('Sohbet başlatılamadı');
  }
}
