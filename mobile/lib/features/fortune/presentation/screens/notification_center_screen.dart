import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPreferencesSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Okunmamış'),
            Tab(text: 'Arşiv'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList('all'),
          _buildNotificationsList('unread'),
          _buildNotificationsList('all'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String filter) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationsAsync = ref.watch(
          notificationsProvider((
            limit: _pageSize,
            offset: _currentPage * _pageSize,
            type: 'all',
            filter: filter,
          )),
        );

        return notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      filter == 'unread' ? 'Yeni bildiri yok' : 'Bildirim yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(context, ref, notification);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Hata: $err'),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final icon = _getNotificationIcon(notification.type);
    final bgColor = notification.read ? Colors.grey[50] : Colors.blue[50];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: bgColor,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              notification.icon ?? icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM HH:mm', 'tr_TR').format(notification.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    notification.read ? Icons.mail_outline : Icons.mail,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(notification.read ? 'Okunmamış Olarak İşaretle' : 'Okundu'),
                ],
              ),
              onTap: () => _toggleReadStatus(ref, notification),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 8),
                  const Text('Sil'),
                ],
              ),
              onTap: () => _deleteNotification(context, ref, notification),
            ),
          ],
        ),
        onTap: () => _showNotificationDetail(context, notification),
      ),
    );
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'daily_reminder':
        return '🔔';
      case 'streak':
        return '🔥';
      case 'achievement':
        return '🏆';
      case 'social':
        return '❤️';
      case 'feature':
        return '✨';
      case 'subscription':
        return '👑';
      default:
        return '📢';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'daily_reminder':
        return Colors.cyan[100]!;
      case 'streak':
        return Colors.orange[100]!;
      case 'achievement':
        return Colors.amber[100]!;
      case 'social':
        return Colors.pink[100]!;
      case 'feature':
        return Colors.purple[100]!;
      case 'subscription':
        return Colors.indigo[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  void _toggleReadStatus(WidgetRef ref, AppNotification notification) {
    final service = ref.read(notificationServiceProvider);
    service.markAsRead(notification.notificationId);
    ref.invalidate(notificationsProvider);
  }

  void _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final service = ref.read(notificationServiceProvider);
    service.deleteNotification(notification.notificationId);
    ref.invalidate(notificationsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim silindi')),
    );
  }

  void _showNotificationDetail(BuildContext context, AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      notification.icon ?? _getNotificationIcon(notification.type),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMMM y HH:mm', 'tr_TR')
                            .format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            if (notification.actionUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Ayrıntıları Gör',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final preferencesAsync = ref.watch(notificationPreferencesProvider);

          return preferencesAsync.when(
            data: (prefs) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bildirim Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPreferenceRow(
                    'Günlük Hatırlatıcı',
                    prefs.dailyReminderEnabled,
                    (value) => _updatePreference('dailyReminderEnabled', value, ref),
                  ),
                  _buildPreferenceRow(
                    'Seri Hatırlatıcısı',
                    prefs.streakReminderEnabled,
                    (value) => _updatePreference('streakReminderEnabled', value, ref),
                  ),
                  _buildPreferenceRow(
                    'Başarılar',
                    prefs.achievementsEnabled,
                    (value) => _updatePreference('achievementsEnabled', value, ref),
                  ),
                  _buildPreferenceRow(
                    'Sosyal Bildirimler',
                    prefs.socialEnabled,
                    (value) => _updatePreference('socialEnabled', value, ref),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kanallar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreferenceRow(
                    'Push Bildirimleri',
                    prefs.pushEnabled,
                    (value) => _updatePreference('pushEnabled', value, ref),
                  ),
                  _buildPreferenceRow(
                    'E-posta',
                    prefs.emailEnabled,
                    (value) => _updatePreference('emailEnabled', value, ref),
                  ),
                  _buildPreferenceRow(
                    'Uygulama İçi',
                    prefs.inAppEnabled,
                    (value) => _updatePreference('inAppEnabled', value, ref),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
          );
        },
      ),
    );
  }

  Widget _buildPreferenceRow(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }

  void _updatePreference(String key, bool value, WidgetRef ref) {
    final updateNotifier = ref.read(updatePreferencesProvider.notifier);
    updateNotifier.updatePreferences({
      key: value,
    });
    ref.invalidate(notificationPreferencesProvider);
  }
}
