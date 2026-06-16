import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/pf_chat.dart';

class PfChatDatasource {
  PfChatDatasource() : _uuid = const Uuid();

  final Uuid _uuid;

  Future<List<PfConversation>> getConversations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_conv_$userId');
    if (raw == null || raw.isEmpty) {
      return [
        PfConversation(
          id: 'conv_demo',
          participantIds: [userId, 't1'],
          lastMessage: 'Merhaba, size nasıl yardımcı olabilirim?',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
          unreadCount: 1,
          tellerName: 'Ayşe Nur',
        ),
      ];
    }
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfConversation(
        id: m['id'] as String,
        participantIds: List<String>.from(m['participantIds'] as List? ?? []),
        lastMessage: m['lastMessage'] as String? ?? '',
        updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        unreadCount: m['unreadCount'] as int? ?? 0,
        tellerName: m['tellerName'] as String?,
        tellerPhotoUrl: m['tellerPhotoUrl'] as String?,
      );
    }).toList();
  }

  Stream<List<PfChatMessage>> watchMessages(String conversationId) async* {
    yield await _loadMessages(conversationId);
  }

  Future<List<PfChatMessage>> _loadMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_msg_$conversationId');
    if (raw == null || raw.isEmpty) {
      return [
        PfChatMessage(
          id: 'm1',
          conversationId: conversationId,
          senderId: 't1',
          type: PfMessageType.text,
          content: 'Merhaba! Kahve falınız için hazırım. Fincan fotoğrafınızı paylaşabilir misiniz?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];
    }
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfChatMessage(
        id: m['id'] as String,
        conversationId: conversationId,
        senderId: m['senderId'] as String? ?? '',
        type: PfMessageType.values.byName(m['type'] as String? ?? 'text'),
        content: m['content'] as String? ?? '',
        mediaUrl: m['mediaUrl'] as String?,
        isRead: m['isRead'] as bool? ?? false,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<PfChatMessage> sendMessage(PfChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pf_msg_${message.conversationId}';
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode({
      'id': message.id,
      'senderId': message.senderId,
      'type': message.type.name,
      'content': message.content,
      'mediaUrl': message.mediaUrl,
      'isRead': message.isRead,
      'createdAt': message.createdAt.toIso8601String(),
    }));
    await prefs.setStringList(key, list);
    return message;
  }

  PfChatMessage createText({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    return PfChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      type: PfMessageType.text,
      content: text,
      createdAt: DateTime.now(),
    );
  }
}
