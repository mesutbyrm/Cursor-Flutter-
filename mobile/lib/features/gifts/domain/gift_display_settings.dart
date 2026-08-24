import '../../../core/util/json_util.dart';

/// Admin panelinden yönetilen global hediye bildirimi ayarları.
/// Kaynak: `GET /api/gifts/display-settings`
class GiftDisplaySettings {
  const GiftDisplaySettings({
    this.enabled = true,
    this.durationMs = 3000,
    this.position = GiftOverlayPosition.topCenter,
    this.size = GiftOverlaySize.small,
    this.maxQueue = 10,
    this.animation = 'slide',
    this.showSender = true,
    this.showReceiver = false,
    this.showGiftName = true,
    this.showAmount = true,
    this.showGiftIcon = true,
    this.maxVisible = 1,
    this.backgroundOpacity = 0.85,
    this.soundEnabled = true,
  });

  factory GiftDisplaySettings.fromJson(Map<String, dynamic> json) {
    return GiftDisplaySettings(
      enabled: json['enabled'] != false,
      durationMs: _intOr(pick(json, ['durationMs', 'duration_ms']), 3000)
          .clamp(800, 15000),
      position: GiftOverlayPosition.parse(
        pick(json, ['position', 'placement'])?.toString(),
      ),
      size: GiftOverlaySize.parse(pick(json, ['size'])?.toString()),
      maxQueue:
          _intOr(pick(json, ['maxQueue', 'max_queue']), 10).clamp(1, 50),
      animation: pick(json, ['animation'])?.toString() ?? 'slide',
      showSender: json['showSender'] != false && json['show_sender'] != false,
      showReceiver: json['showReceiver'] == true || json['show_receiver'] == true,
      showGiftName: json['showGiftName'] != false && json['show_gift_name'] != false,
      showAmount: json['showAmount'] != false && json['show_amount'] != false,
      showGiftIcon: json['showGiftIcon'] != false && json['show_gift_icon'] != false,
      maxVisible:
          _intOr(pick(json, ['maxVisible', 'max_visible']), 1).clamp(1, 3),
      backgroundOpacity: _opacity(
        pick(json, ['backgroundOpacity', 'background_opacity']),
      ),
      soundEnabled: json['soundEnabled'] != false && json['sound_enabled'] != false,
    );
  }

  static double _opacity(dynamic raw) {
    if (raw is num) return raw.clamp(0.2, 1.0).toDouble();
    return double.tryParse('$raw')?.clamp(0.2, 1.0) ?? 0.85;
  }

  static int _intOr(dynamic raw, int fallback) {
    if (raw == null) return fallback;
    final v = asInt(raw);
    return v == 0 && raw != 0 && raw != '0' ? fallback : (v == 0 ? fallback : v);
  }

  final bool enabled;
  final int durationMs;
  final GiftOverlayPosition position;
  final GiftOverlaySize size;
  final int maxQueue;
  final String animation;
  final bool showSender;
  final bool showReceiver;
  final bool showGiftName;
  final bool showAmount;
  final bool showGiftIcon;
  final int maxVisible;
  final double backgroundOpacity;
  final bool soundEnabled;

  Duration get displayDuration => Duration(milliseconds: durationMs);
}

enum GiftOverlayPosition {
  top,
  topCenter,
  topLeft,
  topRight;

  static GiftOverlayPosition parse(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return switch (v) {
      'top' => GiftOverlayPosition.top,
      'topleft' || 'top_left' || 'top-left' => GiftOverlayPosition.topLeft,
      'topright' || 'top_right' || 'top-right' => GiftOverlayPosition.topRight,
      _ => GiftOverlayPosition.topCenter,
    };
  }
}

enum GiftOverlaySize {
  small,
  medium;

  static GiftOverlaySize parse(String? raw) {
    return raw?.trim().toLowerCase() == 'medium'
        ? GiftOverlaySize.medium
        : GiftOverlaySize.small;
  }

  double get height => this == GiftOverlaySize.medium ? 70 : 56;
  double get horizontalMargin => this == GiftOverlaySize.medium ? 12 : 20;
}
