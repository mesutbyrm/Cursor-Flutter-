import 'package:flutter/services.dart';

/// DM mesaj sesi — gönderim ve alım.
class DmMessageSoundService {
  DmMessageSoundService._();

  static final DmMessageSoundService instance = DmMessageSoundService._();

  var _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  Future<void> playIncoming() async {
    if (!_enabled) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> playOutgoing() async {
    if (!_enabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
