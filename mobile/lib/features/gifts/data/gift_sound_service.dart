import '../domain/gift_entity.dart';

import 'gift_sound_pool.dart';

/// Hediye SFX — [GiftSoundPool] üzerinden (geri uyumluluk).
class GiftSoundService {
  GiftSoundService(this._pool);

  final GiftSoundPool _pool;

  Future<void> playFor(GiftEntity gift) => _pool.playFor(gift);

  void dispose() {}
}
