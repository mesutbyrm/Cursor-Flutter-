import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_display_settings.dart';
import '../providers/gift_display_settings_provider.dart';
import 'global_gift_notification.dart';
import 'global_gift_queue.dart';

class GlobalGiftOverlayState {
  const GlobalGiftOverlayState({
    this.active,
    this.settings = const GiftDisplaySettings(),
  });

  final GlobalGiftNotification? active;
  final GiftDisplaySettings settings;

  GlobalGiftOverlayState copyWith({
    GlobalGiftNotification? active,
    bool clearActive = false,
    GiftDisplaySettings? settings,
  }) {
    return GlobalGiftOverlayState(
      active: clearActive ? null : (active ?? this.active),
      settings: settings ?? this.settings,
    );
  }
}

class GlobalGiftOverlayNotifier extends Notifier<GlobalGiftOverlayState> {
  GlobalGiftQueue? _queue;

  @override
  GlobalGiftOverlayState build() {
    final settingsAsync = ref.watch(giftDisplaySettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const GiftDisplaySettings();
    _ensureQueue(settings);
    ref.onDispose(() => _queue?.dispose());
    return GlobalGiftOverlayState(settings: settings);
  }

  void _ensureQueue(GiftDisplaySettings settings) {
    if (_queue == null) {
      _queue = GlobalGiftQueue(settings: settings)
        ..onActiveChanged = (active) {
          state = state.copyWith(active: active, clearActive: active == null);
        };
    } else {
      _queue!.updateSettings(settings);
    }
  }

  bool enqueue(GlobalGiftNotification notification) {
    final settings =
        ref.read(giftDisplaySettingsProvider).valueOrNull ?? state.settings;
    _ensureQueue(settings);
    return _queue!.enqueue(notification);
  }

  void enqueueFromMap(Map<String, dynamic> raw) {
    enqueue(GlobalGiftNotification.fromMap(raw));
  }
}

final globalGiftOverlayProvider =
    NotifierProvider<GlobalGiftOverlayNotifier, GlobalGiftOverlayState>(
  GlobalGiftOverlayNotifier.new,
);
