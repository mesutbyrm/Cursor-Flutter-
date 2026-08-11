import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user_entity.dart';

/// Backend `isBot` / bot role — gerçek kullanıcı aksiyonlarını sınırla.
abstract final class BotAccountGuard {
  static bool fromJsonMap(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return false;
    if (json['isBot'] == true || json['is_bot'] == true) return true;
    final accountType =
        json['accountType']?.toString() ?? json['account_type']?.toString();
    if (accountType?.toLowerCase().trim() == 'bot') return true;
    final role = json['role']?.toString().toLowerCase().trim() ?? '';
    if (role == 'bot' || role.endsWith('_bot')) return true;
    final roles = json['roles'];
    if (roles is List) {
      for (final r in roles) {
        final s = r.toString().toLowerCase();
        if (s.contains('bot')) return true;
      }
    }
    return false;
  }

  static bool isBotUser(UserEntity? user) {
    if (user == null) return false;
    return user.isBot;
  }

  static String blockedMessage(String action) =>
      'Bot hesapları $action yapamaz.';

  static bool blockIfBot(
    WidgetRef ref,
    BuildContext context,
    String action, {
    required bool Function() readIsBot,
  }) {
    if (!readIsBot()) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(blockedMessage(action))),
    );
    return true;
  }
}
