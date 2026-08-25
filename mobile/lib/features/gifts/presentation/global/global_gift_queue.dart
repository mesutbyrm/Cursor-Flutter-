import 'dart:async';

import '../../domain/gift_display_settings.dart';
import 'global_gift_notification.dart';

/// Sıralı hediye bildirimi kuyruğu — admin `maxQueue` ile sınırlı.
class GlobalGiftQueue {
  GlobalGiftQueue({required GiftDisplaySettings settings})
      : _settings = settings;

  GiftDisplaySettings _settings;
  final _pending = <GlobalGiftNotification>[];
  final _seenEventIds = <String>{};
  final _seenSemantic = <String>{};
  GlobalGiftNotification? _active;
  Timer? _hideTimer;
  void Function(GlobalGiftNotification? active)? onActiveChanged;

  GiftDisplaySettings get settings => _settings;

  void updateSettings(GiftDisplaySettings settings) {
    _settings = settings;
    while (_pending.length > _settings.maxQueue) {
      _pending.removeAt(0);
    }
  }

  GlobalGiftNotification? get active => _active;

  bool enqueue(GlobalGiftNotification item) {
    if (!_settings.enabled) return false;
    final id = item.eventId.trim();
    if (id.isEmpty) return false;
    if (!_seenEventIds.add(id)) return false;
    final semantic = item.semanticKey.trim();
    if (semantic.isNotEmpty && !_seenSemantic.add(semantic)) return false;
    if (_seenEventIds.length > 500) {
      _seenEventIds.remove(_seenEventIds.first);
    }
    if (_seenSemantic.length > 500) {
      _seenSemantic.remove(_seenSemantic.first);
    }
    if (_active == null) {
      _show(item);
      return true;
    }
    if (_pending.length >= _settings.maxQueue) {
      _pending.removeAt(0);
    }
    _pending.add(item);
    return true;
  }

  void _show(GlobalGiftNotification item) {
    _hideTimer?.cancel();
    _active = item;
    onActiveChanged?.call(item);
    _hideTimer = Timer(_settings.displayDuration, _advance);
  }

  void _advance() {
    _hideTimer?.cancel();
    if (_pending.isEmpty) {
      _active = null;
      onActiveChanged?.call(null);
      return;
    }
    _show(_pending.removeAt(0));
  }

  void dispose() {
    _hideTimer?.cancel();
    _pending.clear();
    _active = null;
  }
}
