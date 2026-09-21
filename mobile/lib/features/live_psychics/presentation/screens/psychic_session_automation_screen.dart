import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicSessionAutomationScreen extends ConsumerStatefulWidget {
  const PsychicSessionAutomationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicSessionAutomationScreen> createState() =>
      _PsychicSessionAutomationScreenState();
}

class _PsychicSessionAutomationScreenState
    extends ConsumerState<PsychicSessionAutomationScreen>
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
            'Seans Planlama',
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
              Tab(text: 'Takvim'),
              Tab(text: 'Otomasyon'),
              Tab(text: 'Hatırlatıcılar'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ScheduleCalendarTab(),
            _AutomationRulesTab(),
            _RemindersTab(),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCalendarTab extends StatefulWidget {
  @override
  State<_ScheduleCalendarTab> createState() => _ScheduleCalendarTabState();
}

class _ScheduleCalendarTabState extends State<_ScheduleCalendarTab> {
  late List<Map<String, dynamic>> scheduledSessions;

  @override
  void initState() {
    super.initState();
    scheduledSessions = [
      {
        'date': '2026-09-22',
        'time': '14:00',
        'customer': 'Ayşe Kara',
        'type': 'Tarot',
        'duration': '30 min',
        'status': 'Tamamlandı',
      },
      {
        'date': '2026-09-23',
        'time': '16:30',
        'customer': 'Zeynep Mert',
        'type': 'Astroloji',
        'duration': '45 min',
        'status': 'Planlandı',
      },
      {
        'date': '2026-09-24',
        'time': '10:00',
        'customer': 'Fatma Yıldız',
        'type': 'Rehberlik',
        'duration': '25 min',
        'status': 'Planlandı',
      },
      {
        'date': '2026-09-25',
        'time': '13:15',
        'customer': 'Emre Demir',
        'type': 'Numeroloji',
        'duration': '35 min',
        'status': 'Planlandı',
      },
      {
        'date': '2026-09-26',
        'time': '15:00',
        'customer': 'Müge Şahin',
        'type': 'Tarot',
        'duration': '40 min',
        'status': 'Planlandı',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Planlanmış Seanslar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...scheduledSessions.map((session) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['customer'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              '${session["date"]} ${session["time"]}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: session['status'] == 'Tamamlandı'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session['status'],
                      style: TextStyle(
                        fontSize: 10,
                        color: session['status'] == 'Tamamlandı'
                            ? Colors.green
                            : Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppThemeColors.accentCyan
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session['type'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppThemeColors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session['duration'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Düzenle'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${session["customer"]} seansı düzenlendi',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('İptal Et'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${session["customer"]} seansı iptal edildi',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni seans planlaması açılıyor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Seans Planla'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeColors.accentCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _AutomationRulesTab extends StatefulWidget {
  @override
  State<_AutomationRulesTab> createState() => _AutomationRulesTabState();
}

class _AutomationRulesTabState extends State<_AutomationRulesTab> {
  late List<Map<String, dynamic>> automationRules;

  @override
  void initState() {
    super.initState();
    automationRules = [
      {
        'name': 'Otomatik Onaylandı (İlk 10 Seans)',
        'description': 'İlk 10 seansını otomatik olarak onayla',
        'enabled': true,
        'icon': Icons.done_all_rounded,
      },
      {
        'name': 'Gecikmiş Seansları Reddet',
        'description': 'Geç saatlerdeki istekleri otomatik olarak reddet',
        'enabled': true,
        'icon': Icons.block_rounded,
      },
      {
        'name': 'Düşük Puanlı Müşterileri Filtrele',
        'description': '3 yıldızdan düşük müşteri isteklerini gözden geçir',
        'enabled': false,
        'icon': Icons.filter_list_rounded,
      },
      {
        'name': 'Uzun Seanslara Öncelik Ver',
        'description': '40+ dakikalık seansları önce göster',
        'enabled': true,
        'icon': Icons.priority_high_rounded,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Otomasyon Kuralları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...automationRules.asMap().entries.map((entry) {
          final index = entry.key;
          final rule = entry.value;
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
                Icon(rule['icon'] as IconData,
                    color: rule['enabled'] as bool
                        ? AppThemeColors.accentCyan
                        : Colors.white54,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule['description'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule['enabled'] as bool,
                  onChanged: (value) {
                    setState(() {
                      automationRules[index]['enabled'] = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? '${rule["name"]} etkinleştirildi'
                              : '${rule["name"]} devre dışı bırakıldı',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeColor: AppThemeColors.accentCyan,
                  inactiveThumbColor: Colors.grey[600],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
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
                      'Otomasyon İpucu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kuralları çalışma stiline göre özelleştir',
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
}

class _RemindersTab extends StatefulWidget {
  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  late List<Map<String, dynamic>> reminders;

  @override
  void initState() {
    super.initState();
    reminders = [
      {
        'title': 'Seans Başlamak Üzere',
        'description': 'Seans başlamadan 15 dakika önce hatırlat',
        'enabled': true,
        'icon': Icons.schedule_rounded,
        'time': '15 dakika',
      },
      {
        'title': 'Hazırlık Zamanı',
        'description': 'Seans başlamadan 30 dakika önce bildir',
        'enabled': true,
        'icon': Icons.notifications_rounded,
        'time': '30 dakika',
      },
      {
        'title': 'Seans Bitişinden Sonra',
        'description': 'Seans bitince müşteri değerlendirme hatırla',
        'enabled': false,
        'icon': Icons.rate_review_rounded,
        'time': 'Hemen',
      },
      {
        'title': 'Takip Mesajı',
        'description': 'Seans sonrası müşteriye takip mesajı gönder',
        'enabled': true,
        'icon': Icons.message_rounded,
        'time': '24 saat sonra',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Hatırlatıcı ve Bildirimler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...reminders.asMap().entries.map((entry) {
          final index = entry.key;
          final reminder = entry.value;
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
                    color: reminder['enabled'] as bool
                        ? AppThemeColors.accentCyan.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(reminder['icon'] as IconData,
                      color: reminder['enabled'] as bool
                          ? AppThemeColors.accentCyan
                          : Colors.grey,
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder['title'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder['description'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reminder['time'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder['enabled'] as bool,
                  onChanged: (value) {
                    setState(() {
                      reminders[index]['enabled'] = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? '${reminder["title"]} etkinleştirildi'
                              : '${reminder["title"]} devre dışı bırakıldı',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeColor: AppThemeColors.accentCyan,
                  inactiveThumbColor: Colors.grey[600],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: Colors.purple, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hatırlatıcı İpucu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tüm hatırlatıcıları aktif tut, seansını hiç kaçırma',
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
}
