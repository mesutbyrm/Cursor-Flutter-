import '../../notifications/domain/entities/app_notification_entity.dart';
import 'inbox_notification_filters.dart';

/// Sistem Mesajları ekranı açılınca yalnız SİSTEM bildirimlerini okundu yapar.
///
/// `markAll` kullanılmaz: o, DM/sohbet türündeki bildirimleri de okundu yapar.
/// Bunun yerine okunmamışlar sayfalanır, [filterSystemNotifications] ile
/// süzülür ve yalnız bu kimlikler `notificationIds` ile gönderilir.
/// Sunucu işlemi idempotenttir; tekrar çalıştırmak zararsızdır.
class SystemNotificationsReadSync {
  SystemNotificationsReadSync({
    required this.fetchUnreadPage,
    required this.markReadIds,
    this.pageSize = 50,
    this.maxPages = 20,
    this.chunkSize = 100,
  });

  final Future<List<AppNotificationEntity>> Function(int page) fetchUnreadPage;
  final Future<void> Function(List<String> ids) markReadIds;
  final int pageSize;
  final int maxPages;
  final int chunkSize;

  /// Okundu yapılan sistem bildirimi kimliklerini döner. Hata olursa fırlatır;
  /// çağıran yerel durumu değiştirmemeli ve yeniden deneme sunmalıdır.
  Future<Set<String>> run() async {
    final unread = <AppNotificationEntity>[];
    for (var page = 1; page <= maxPages; page++) {
      final rows = await fetchUnreadPage(page);
      unread.addAll(rows.where((n) => !n.read));
      if (rows.length < pageSize) break;
    }
    final ids = <String>{
      for (final n in filterSystemNotifications(unread))
        if (n.id.trim().isNotEmpty) n.id,
    };
    if (ids.isEmpty) return ids;
    final list = ids.toList();
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = i + chunkSize > list.length ? list.length : i + chunkSize;
      await markReadIds(list.sublist(i, end));
    }
    return ids;
  }
}
