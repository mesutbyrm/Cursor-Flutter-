import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının açıp kapatabildiği bildirim kanalları.
///
/// Android kanal kimlikleri (`id`) sabittir — sistem ayarlarında da bu isimlerle
/// görünür. Eski kanallar (`canlifal_default`, `canlifal_urgent`) sunucunun
/// OneSignal/FCM ile hedeflediği kimlikler olduğundan korunur.
enum AppNotificationChannel {
  messages(
    id: 'canlifal_messages',
    label: 'Mesajlar',
    description: 'Direkt mesaj bildirimleri (yanıtlanabilir)',
    prefsKey: 'notif_channel_messages_v1',
  ),
  liveStarters(
    id: 'canlifal_live',
    label: 'Canlı yayın başlatanlar',
    description: 'Takip ettiklerin canlı yayına başladığında',
    prefsKey: 'notif_channel_live_v1',
  ),
  dailyFortune(
    id: 'canlifal_daily_fortune',
    label: 'Günlük fal önerisi',
    description: 'Günlük fal ve burç hatırlatmaları',
    prefsKey: 'notif_channel_daily_fortune_v1',
  ),
  other(
    id: 'canlifal_other',
    label: 'Diğer',
    description: 'Beğeni, yorum, ödeme ve diğer bildirimler',
    prefsKey: 'notif_channel_other_v1',
  );

  const AppNotificationChannel({
    required this.id,
    required this.label,
    required this.description,
    required this.prefsKey,
  });

  final String id;
  final String label;
  final String description;
  final String prefsKey;

  /// Sunucu bildirim `type` değerinden kanal.
  static AppNotificationChannel forType(String? rawType) {
    final t = (rawType ?? '').toLowerCase();
    if (t.contains('message') || t.contains('chat') || t == 'dm') {
      return AppNotificationChannel.messages;
    }
    if (t.contains('live') || t.contains('stream') || t.contains('broadcast')) {
      // streamEnded / pk olayları "yayın başlatanlar" değildir.
      if (t.contains('ended') || t.contains('pk')) {
        return AppNotificationChannel.other;
      }
      return AppNotificationChannel.liveStarters;
    }
    if (t.contains('daily') ||
        t.contains('horoscope') ||
        t.contains('gunluk') ||
        t.contains('günlük')) {
      return AppNotificationChannel.dailyFortune;
    }
    return AppNotificationChannel.other;
  }
}

/// Kanal tercihleri — cihazda (SharedPreferences) tutulur.
///
/// NOT: Backend'de bildirim tercihi saklayan bir uç yoktur (kontrol edildi);
/// tercihler bu cihazda uygulanır. Arka plan isolate'ında da okunabilir.
class NotificationChannelPrefs {
  const NotificationChannelPrefs();

  Future<bool> isEnabled(AppNotificationChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(channel.prefsKey) ?? true;
  }

  Future<void> setEnabled(AppNotificationChannel channel, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(channel.prefsKey, enabled);
  }

  Future<Map<AppNotificationChannel, bool>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final c in AppNotificationChannel.values)
        c: prefs.getBool(c.prefsKey) ?? true,
    };
  }
}
