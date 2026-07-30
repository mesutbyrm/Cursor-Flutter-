import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/gift_entity.dart';
import '../domain/gift_rarity.dart';
import '../../../live/domain/entities/live_gift_event.dart';

/// Kısa hediye SFX havuzu — eşzamanlı çalma, önbellekli kaynak.
class GiftSoundPool {
  GiftSoundPool({this.poolSize = 4}) {
    for (var i = 0; i < poolSize; i++) {
      final p = AudioPlayer();
      p.setVolume(1);
      _players.add(p);
      _busy.add(false);
    }
  }

  final int poolSize;
  final _players = <AudioPlayer>[];
  final _busy = <bool>[];
  final _preloaded = <String, AudioSource>{};

  int _rr = 0;

  Future<void> preloadUrl(String? url) async {
    if (url == null || url.isEmpty || !url.startsWith('http')) return;
    if (_preloaded.containsKey(url)) return;
    try {
      _preloaded[url] = AudioSource.uri(Uri.parse(url));
    } catch (_) {}
  }

  Future<void> preloadGift(GiftEntity gift) async {
    await preloadUrl(gift.soundUrl);
  }

  Future<void> playForEvent(LiveGiftEvent event, {GiftEntity? catalog}) async {
    final url = event.soundKey?.startsWith('http') == true
        ? event.soundKey
        : catalog?.soundUrl;
    final key = catalog?.soundKey ?? event.soundKey;
    final rarity = catalog?.rarity ?? GiftRarity.common;

    final played = await _playUrl(url) ||
        await _playAsset(key) ||
        await _playAsset(_rarityAsset(rarity));
    if (!played) {
      await _playSystem(rarity);
    }
    _haptic(rarity);
  }

  Future<void> playFor(GiftEntity gift) => playForEvent(
        LiveGiftEvent(
          id: 'local-sfx',
          senderName: '',
          receiverName: '',
          giftId: gift.id,
          giftName: gift.name,
          quantity: 1,
          coinCost: gift.price,
          giftPrice: gift.price,
          totalCoin: gift.price,
          totalDiamond: 0,
          combo: 1,
          timestamp: DateTime.now(),
          soundKey: gift.soundKey,
        ),
        catalog: gift,
      );

  Future<bool> _playUrl(String? url) async {
    if (url == null || url.isEmpty || !url.startsWith('http')) return false;
    final idx = _acquire();
    if (idx < 0) return false;
    try {
      final source = _preloaded[url] ?? AudioSource.uri(Uri.parse(url));
      await _players[idx].setAudioSource(source);
      await _players[idx].play();
      _scheduleRelease(idx);
      return true;
    } catch (_) {
      _busy[idx] = false;
      return false;
    }
  }

  Future<bool> _playAsset(String? key) async {
    if (key == null || key.isEmpty) return false;
    if (key.startsWith('http')) return _playUrl(key);
    final path = key.contains('/')
        ? key
        : 'assets/gifts/sounds/$key.mp3';
    final idx = _acquire();
    if (idx < 0) return false;
    try {
      await _players[idx].setAsset(path.replaceFirst('assets/', ''));
      await _players[idx].play();
      _scheduleRelease(idx);
      return true;
    } catch (_) {
      _busy[idx] = false;
      return false;
    }
  }

  int _acquire() {
    for (var i = 0; i < poolSize; i++) {
      final j = (_rr + i) % poolSize;
      if (!_busy[j]) {
        _busy[j] = true;
        _rr = (j + 1) % poolSize;
        return j;
      }
    }
    return -1;
  }

  void _scheduleRelease(int idx) {
    unawaited(
      _players[idx].playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).then((_) {
        _busy[idx] = false;
      }).catchError((_) {
        _busy[idx] = false;
      }),
    );
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

  Future<void> dispose() async {
    for (final p in _players) {
      await p.dispose();
    }
    _players.clear();
    _busy.clear();
    _preloaded.clear();
  }
}
