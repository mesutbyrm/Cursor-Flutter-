import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../domain/gift_entity.dart';
import '../domain/gift_rarity.dart';

/// Hediye SFX — rarity’ye göre farklı geri bildirim.
class GiftSoundService {
  GiftSoundService() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;
  var _busy = false;

  Future<void> playFor(GiftEntity gift) async {
    if (_busy) return;
    _busy = true;
    try {
      final played = await _playAsset(gift.soundKey) ||
          await _playAsset(_rarityAsset(gift.rarity));
      if (!played) {
        await _playSystem(gift.rarity);
      }
      _haptic(gift.rarity);
    } finally {
      _busy = false;
    }
  }

  Future<bool> _playAsset(String? key) async {
    if (key == null || key.isEmpty) return false;
    final path = key.contains('/')
        ? key
        : 'assets/gifts/sounds/$key.mp3';
    try {
      await _player.play(AssetSource(path.replaceFirst('assets/', '')));
      return true;
    } catch (_) {
      return false;
    }
  }

  String _rarityAsset(GiftRarity r) => switch (r) {
        GiftRarity.mythic => 'mythic',
        GiftRarity.legendary => 'legendary',
        GiftRarity.epic => 'epic',
        GiftRarity.rare => 'rare',
        GiftRarity.common => 'common',
      };

  Future<void> _playSystem(GiftRarity rarity) async {
    try {
      await SystemSound.play(
        rarity.index >= GiftRarity.epic.index
            ? SystemSoundType.alert
            : SystemSoundType.click,
      );
    } catch (_) {}
  }

  void _haptic(GiftRarity rarity) {
    switch (rarity) {
      case GiftRarity.mythic:
      case GiftRarity.legendary:
        HapticFeedback.heavyImpact();
      case GiftRarity.epic:
        HapticFeedback.mediumImpact();
      default:
        HapticFeedback.lightImpact();
    }
  }

  void dispose() {
    _player.dispose();
  }
}
