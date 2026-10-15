import 'package:flutter/material.dart';

/// GirLive Bot profil resmi — sohbet satırlarında harf yerine bot görseli.
abstract final class GirLiveBotAvatar {
  static const asset = 'assets/brand/girlive_bot.png';

  /// Mesaj sahibi GirLive Bot mu? (ad veya kullanıcı kimliği üzerinden)
  static bool isBot({String? name, String? userId}) {
    final n = (name ?? '').toLowerCase();
    final id = (userId ?? '').toLowerCase();
    return n.contains('girlive') || id == 'girlive-bot';
  }

  static Widget circle({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF7C3AED),
      backgroundImage: const AssetImage(asset),
    );
  }
}
