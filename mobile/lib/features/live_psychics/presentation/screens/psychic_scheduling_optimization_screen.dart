import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicSchedulingOptimizationScreen extends ConsumerStatefulWidget {
  const PsychicSchedulingOptimizationScreen({super.key});

  @override
  ConsumerState<PsychicSchedulingOptimizationScreen> createState() =>
      _PsychicSchedulingOptimizationScreenState();
}

class _PsychicSchedulingOptimizationScreenState
    extends ConsumerState<PsychicSchedulingOptimizationScreen>
    with TickerProviderStateMixin {
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
    return Scaffold(
      body: Stack(
        children: [
          const CosmicGalaxyBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Planlama Optimizasyonu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purple.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kullanılabilirlik',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '76% (Bu Hafta)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Doldurulma Oranı',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '62%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: AppThemeColors.accentCyan,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Takvim'),
                    Tab(text: 'Örüntü'),
                    Tab(text: 'Öneriler'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _CalendarTab(),
                      _PatternsTab(),
                      _RecommendationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu Hafta Planlanması',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  ...[
                    {'day': 'Pazartesi', 'available': 8, 'booked': 5, 'pending': 1},
                    {'day': 'Salı', 'available': 8, 'booked': 8, 'pending': 0},
                    {'day': 'Çarşamba', 'available': 8, 'booked': 3, 'pending': 2},
                    {'day': 'Perşembe', 'available': 8, 'booked': 6, 'pending': 1},
                    {'day': 'Cuma', 'available': 8, 'booked': 7, 'pending': 0},
                    {'day': 'Cumartesi', 'available': 6, 'booked': 6, 'pending': 0},
                    {'day': 'Pazar', 'available': 4, 'booked': 3, 'pending': 1},
                  ].asMap().entries.map((entry) {
                    final dayData = entry.value;
                    final totalSlots = dayData['available'] as int;
                    final booked = dayData['booked'] as int;
                    final pending = dayData['pending'] as int;
                    final available = totalSlots - booked;
                    final fillRate = ((booked + pending) / totalSlots * 100).toInt();

                    return Column(
                      children: [
                        if (entry.key > 0)
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dayData['day'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$fillRate% Dolu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: fillRate >= 80
                                          ? Colors.red
                                          : fillRate >= 50
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fillRate / 100,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(
                                    fillRate >= 80
                                        ? Colors.red
                                        : fillRate >= 50
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Tutuldu: $booked',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Beklemede: $pending',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Boş: $available',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Günlük Zamanlar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  ...[
                    {'slot': '09:00 - 10:00', 'status': 'Tutuldu', 'customer': 'Müşteri 1'},
                    {'slot': '10:00 - 11:00', 'status': 'Boş', 'customer': '-'},
                    {'slot': '11:00 - 12:00', 'status': 'Tutuldu', 'customer': 'Müşteri 2'},
                    {'slot': '12:00 - 13:00', 'status': 'Beklemede', 'customer': 'Müşteri 3'},
                    {'slot': '13:00 - 14:00', 'status': 'Boş', 'customer': '-'},
                    {'slot': '20:00 - 21:00', 'status': 'Tutuldu', 'customer': 'Müşteri 4'},
                    {'slot': '21:00 - 22:00', 'status': 'Tutuldu', 'customer': 'Müşteri 5'},
                  ].asMap().entries.map((entry) {
                    final slotData = entry.value;
                    final status = slotData['status'] as String;
                    final statusColor = status == 'Tutuldu'
                        ? Colors.blue
                        : status == 'Beklemede'
                            ? Colors.yellow
                            : Colors.green;

                    return Column(
                      children: [
                        if (entry.key > 0)
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slotData['slot'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      slotData['customer'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternsTab extends StatelessWidget {
  const _PatternsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talep Örüntüleri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PeakHourBar(height: 0.6, hour: '09'),
                      _PeakHourBar(height: 0.75, hour: '10'),
                      _PeakHourBar(height: 0.85, hour: '11'),
                      _PeakHourBar(height: 0.7, hour: '12'),
                      _PeakHourBar(height: 0.4, hour: '13'),
                      _PeakHourBar(height: 0.35, hour: '14'),
                      _PeakHourBar(height: 0.5, hour: '20'),
                      _PeakHourBar(height: 0.95, hour: '21'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Yoğunluk: 21:00 saati en talep gören zaman dilimi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gün İçinde Popülarite',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'day': 'Pazartesi',
                'bookings': 145,
                'ratio': 62,
                'trend': '+8%',
              },
              {
                'day': 'Salı',
                'bookings': 178,
                'ratio': 76,
                'trend': '+12%',
              },
              {
                'day': 'Çarşamba',
                'bookings': 98,
                'ratio': 42,
                'trend': '-5%',
              },
              {
                'day': 'Perşembe',
                'bookings': 156,
                'ratio': 67,
                'trend': '+3%',
              },
              {
                'day': 'Cuma',
                'bookings': 189,
                'ratio': 81,
                'trend': '+15%',
              },
              {
                'day': 'Cumartesi',
                'bookings': 204,
                'ratio': 92,
                'trend': '+18%',
              },
              {
                'day': 'Pazar',
                'bookings': 142,
                'ratio': 64,
                'trend': '+6%',
              },
            ].map((day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day['day'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              day['trend'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rezervasyon',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day['bookings']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (day['ratio'] as int) / 100,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  (day['ratio'] as int) >= 80
                                      ? Colors.red
                                      : (day['ratio'] as int) >= 50
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akıllı Öneriler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'title': 'Çarşamba Günü Tanıtım',
                'desc': 'Çarşamba trafiği %42 daha düşük. Özel indirim sunmayı deneyin.',
                'impact': '+28% Potansiyel Rezervasyon',
                'icon': Icons.trending_down_rounded,
              },
              {
                'title': '13:00-14:00 Slot Kapalı',
                'desc': 'Bu saat dilimi sürekli boş. Silin ve diğer zamanları uzatın.',
                'impact': '+15% Doldurma Oranı',
                'icon': Icons.schedule_rounded,
              },
              {
                'title': 'Hafta Sonu Kapasite Artırma',
                'desc': 'Cumartesi-Pazar %90+ talep görüyor. Daha fazla slot ekleyin.',
                'impact': '+₺2,100 Aylık Gelir',
                'icon': Icons.add_circle_outline_rounded,
              },
              {
                'title': '21:00 Sonrası Slot Ekleyin',
                'desc': '21:00 saati en yoğun. 22:00 ve 23:00 slotları eklemek faydalı olabilir.',
                'impact': '+₺1,850 Aylık Gelir',
                'icon': Icons.access_time_rounded,
              },
              {
                'title': 'Pazarlama Kampanyası',
                'desc': 'Düşük günlerde promosyon yaparak talep 2-3 katlı artırabilirsiniz.',
                'impact': '+₺3,500 Aylık Potansiyel',
                'icon': Icons.megaphone_rounded,
              },
            ].map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppThemeColors.accentCyan
                                  .withValues(alpha: 0.3),
                            ),
                            child: Icon(
                              rec['icon'] as IconData,
                              color: AppThemeColors.accentCyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rec['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rec['impact'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'Uygula',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PeakHourBar extends StatelessWidget {
  const _PeakHourBar({required this.height, required this.hour});

  final double height;
  final String hour;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 100 * height,
          decoration: BoxDecoration(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hour,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
