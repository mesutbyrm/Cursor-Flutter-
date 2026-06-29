import 'package:flutter/material.dart';

import '../../domain/entities/chat_room_presence.dart';

/// Faz 11 — @ etiket algılama ve oda kullanıcılarına eşleme.
class VoiceRoomMentionQuery {
  const VoiceRoomMentionQuery({
    required this.atIndex,
    required this.query,
  });

  final int atIndex;
  final String query;
}

abstract final class VoiceRoomMention {
  static final _handlePattern = RegExp(r'@([^\s@]+)');

  static VoiceRoomMentionQuery? detectQuery(String text, TextSelection selection) {
    final cursor = selection.isValid ? selection.baseOffset : text.length;
    if (cursor <= 0 || cursor > text.length) return null;
    final before = text.substring(0, cursor);
    final at = before.lastIndexOf('@');
    if (at < 0) return null;
    if (at > 0) {
      final prev = before[at - 1];
      if (prev != ' ' && prev != '\n') return null;
    }
    final query = before.substring(at + 1);
    if (query.contains(' ') || query.contains('\n')) return null;
    return VoiceRoomMentionQuery(atIndex: at, query: query);
  }

  static String handleFor(ChatRoomPresence user) {
    final nick = user.nickname?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return user.displayName.trim().isNotEmpty ? user.displayName.trim() : user.name.trim();
  }

  static List<ChatRoomPresence> filterSuggestions({
    required List<ChatRoomPresence> presence,
    required String query,
    String? excludeUserId,
  }) {
    final q = query.trim().toLowerCase();
    final users = presence.where((p) => p.id.isNotEmpty && p.id != excludeUserId).toList()
      ..sort((a, b) => handleFor(a).toLowerCase().compareTo(handleFor(b).toLowerCase()));
    if (q.isEmpty) return users.take(8).toList();
    return users
        .where((p) {
          final handle = handleFor(p).toLowerCase();
          final name = p.displayName.toLowerCase();
          return handle.startsWith(q) || name.startsWith(q) || handle.contains(q);
        })
        .take(8)
        .toList();
  }

  static List<String> resolveMentionedUserIds(
    String content,
    List<ChatRoomPresence> presence,
  ) {
    final handles = _handlePattern
        .allMatches(content)
        .map((m) => m.group(1)?.trim().toLowerCase() ?? '')
        .where((h) => h.isNotEmpty)
        .toSet();
    if (handles.isEmpty) return const [];

    final ids = <String>{};
    for (final user in presence) {
      final keys = {
        handleFor(user).toLowerCase(),
        user.displayName.trim().toLowerCase(),
        user.name.trim().toLowerCase(),
        user.nickname?.trim().toLowerCase(),
      }.whereType<String>().where((k) => k.isNotEmpty);
      if (handles.any(keys.contains)) {
        ids.add(user.id);
      }
    }
    return ids.toList();
  }

  static void insertMention({
    required TextEditingController controller,
    required String handle,
    required VoiceRoomMentionQuery trigger,
  }) {
    final text = controller.text;
    final cursor = controller.selection.isValid
        ? controller.selection.baseOffset
        : text.length;
    final before = text.substring(0, trigger.atIndex);
    final after = text.substring(cursor);
    final insert = '@$handle ';
    final next = '$before$insert$after';
    final offset = before.length + insert.length;
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
