import 'package:flutter/material.dart';

/// GirLive Bot profil resmi — sohbet satırlarında harf yerine bot görseli.
abstract final class GirLiveBotAvatar {
  static const asset = 'assets/brand/girlive_bot.png';

  static String _squash(String? v) =>
      (v ?? '').toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  /// Mesaj sahibi GirLive Bot mu?
  ///
  /// Yalnızca kimlik ya da görünen ad BİREBİR bot olduğunda true döner
  /// (`girlive-bot`, `girlive_bot`, `GirLive Bot`). Adında «girlive» geçen sıradan
  /// bir kullanıcı (ör. «girlivehayran») bot resmi taşıyamaz.
  static bool isBot({String? name, String? userId}) {
    const bot = 'girlivebot';
    return _squash(userId) == bot || _squash(name) == bot;
  }

  static Widget circle({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF7C3AED),
      backgroundImage: const AssetImage(asset),
    );
  }
}
