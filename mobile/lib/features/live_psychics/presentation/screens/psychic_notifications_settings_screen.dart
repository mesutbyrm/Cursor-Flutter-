import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicNotificationsSettingsScreen extends ConsumerStatefulWidget {
  const PsychicNotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicNotificationsSettingsScreen> createState() =>
      _PsychicNotificationsSettingsScreenState();
}

class _PsychicNotificationsSettingsScreenState
    extends ConsumerState<PsychicNotificationsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return DiscoverBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          centerTitle: true,
          title: const Text(
            'Bildirim Ayarları',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppThemeColors.accentCyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Tercihler'),
              Tab(text: 'Zamanlamalar'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _PreferencesTab(),
            _ScheduleTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _PreferencesTab extends StatefulWidget {
  @override
  State<_PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<_PreferencesTab> {
  late Map<String, bool> notificationSettings;

  @override
  void initState() {
    super.initState();
    notificationSettings = {
      'sessionRequests': true,
      'customerMessages': true,
      'reviews': true,
      'earnings': true,
      'achievements': false,
      'promotions': true,
      'systemUpdates': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Seans & Müşteri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildNotificationToggle(
          'Yeni Seans İsteği',
          'Müşteri seni seansa davet ettiğinde bildir',
          'sessionRequests',
          Icons.event_available_rounded,
          Colors.green,
        ),
        _buildNotificationToggle(
          'Müşteri Mesajları',
          'Yeni mesaj aldığında anında haber ver',
          'customerMessages',
          Icons.message_rounded,
          Colors.blue,
        ),
        _buildNotificationToggle(
          'Yorum & Puanlamalar',
          'Yeni yorum ya da yıldız aldığında bildir',
          'reviews',
          Icons.star_rounded,
          Colors.amber,
        ),
        const SizedBox(height: 24),
        const Text(
          'Gelirler & Ödüller',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildNotificationToggle(
          'Kazanç Bildirimleri',
          'Seans tamamlandığında gelir notu al',
          'earnings',
          Icons.attach_money_rounded,
          Colors.green,
        ),
        _buildNotificationToggle(
          'Başarılar & Rozetler',
          'Yeni rozet ya da başarı elde ettiğinde bildir',
          'achievements',
          Icons.emoji_events_rounded,
          Colors.purple,
        ),
        const SizedBox(height: 24),
        const Text(
          'Platform & Promosyon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildNotificationToggle(
          'Promosyon & Teklifler',
          'Özel promosyon ve fırsat bildirimleri',
          'promotions',
          Icons.local_offer_rounded,
          Colors.orange,
        ),
        _buildNotificationToggle(
          'Sistem Güncellemeleri',
          'Önemli sistem değişiklikleri ve bakım',
          'systemUpdates',
          Icons.build_circle_rounded,
          Colors.cyan,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppThemeColors.accentCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kritik Bildirimler',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Hesap güvenliği ve önemli mesajlar her zaman gönderilir',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String description,
    String key,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Switch(
            value: notificationSettings[key] ?? false,
            onChanged: (value) {
              setState(() {
                notificationSettings[key] = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? '$title açıldı' : '$title kapatıldı',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            activeColor: color,
            inactiveThumbColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  late Map<String, Map<String, String>> schedules;

  @override
  void initState() {
    super.initState();
    schedules = {
      'Pazartesi': {'start': '09:00', 'end': '23:00'},
      'Salı': {'start': '09:00', 'end': '23:00'},
      'Çarşamba': {'start': '09:00', 'end': '23:00'},
      'Perşembe': {'start': '10:00', 'end': '00:00'},
      'Cuma': {'start': '10:00', 'end': '00:00'},
      'Cumartesi': {'start': '14:00', 'end': '02:00'},
      'Pazar': {'start': '15:00', 'end': '23:00'},
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Bildirim Zamanlaması',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bu saatlerde bildirimleri al',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        ...schedules.entries.map(
          (entry) => _buildScheduleRow(
            entry.key,
            entry.value['start']!,
            entry.value['end']!,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acil Çağrılar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Müşteri çok uygun kıymetli seslerini her zaman alırsın',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String day, String startTime, String endTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$day için saat düzenlenecek'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppThemeColors.accentCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Son Bildirimler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...[
          {
            'title': 'Yeni Seans İsteği',
            'description': 'Ayşe K. sana seans isteği gönderdi',
            'time': '2 dakika önce',
            'type': 'request',
            'color': Colors.green,
            'read': false,
          },
          {
            'title': 'Müşteri Mesajı',
            'description': 'Zeynep M. seni "Çok doğru tahmin yapıyorsun!" diye övdü',
            'time': '15 dakika önce',
            'type': 'message',
            'color': Colors.blue,
            'read': false,
          },
          {
            'title': '5 Yıldız Aldın',
            'description': 'Seansında 5 yıldız puanı aldın',
            'time': '1 saat önce',
            'type': 'rating',
            'color': Colors.amber,
            'read': true,
          },
          {
            'title': 'Kazanç Doğrulandı',
            'description': '₺125.50 kazancın ödeme sistemine eklendi',
            'time': '2 saat önce',
            'type': 'earning',
            'color': Colors.green,
            'read': true,
          },
          {
            'title': 'Rozet Açıldı',
            'description': '"İlk 10 Seans" rozetini açtın!',
            'time': '3 saat önce',
            'type': 'badge',
            'color': Colors.purple,
            'read': true,
          },
          {
            'title': 'Promosyon',
            'description': 'Arkadaş daveti yaparak %10 bonus kazan',
            'time': '5 saat önce',
            'type': 'promotion',
            'color': Colors.orange,
            'read': true,
          },
        ].map((notification) => _buildNotificationCard(notification)),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (notification['read'] as bool)
            ? Colors.white.withValues(alpha: 0.03)
            : (notification['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (notification['read'] as bool)
              ? Colors.white.withValues(alpha: 0.1)
              : (notification['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: notification['color'],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!(notification['read'] as bool))
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppThemeColors.accentCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['description'],
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['time'],
                  style: TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
