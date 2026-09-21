import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicGrowthMetricsScreen extends ConsumerStatefulWidget {
  const PsychicGrowthMetricsScreen({super.key});

  @override
  ConsumerState<PsychicGrowthMetricsScreen> createState() =>
      _PsychicGrowthMetricsScreenState();
}

class _PsychicGrowthMetricsScreenState
    extends ConsumerState<PsychicGrowthMetricsScreen>
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
                              'Büyüme Metrikleri',
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
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yıllık Büyüme',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '+38%',
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
                                  'Hedef',
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
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '+50%',
                                    style: TextStyle(
                                      fontSize: 12,
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
                    Tab(text: 'KPI\'ler'),
                    Tab(text: 'Hedefler'),
                    Tab(text: 'İlerleme'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _KPIsTab(),
                      _GoalsTab(),
                      _ProgressTab(),
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

class _KPIsTab extends StatelessWidget {
  const _KPIsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ana Performans Göstergeleri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'title': 'Aylık Gelir',
                'value': '₺24,580',
                'change': '+18% vs Geçen Ay',
                'target': '₺30,000',
                'progress': 82,
                'icon': Icons.payment_rounded,
              },
              {
                'title': 'Aylık Seanslar',
                'value': '127',
                'change': '+12% vs Geçen Ay',
                'target': '150',
                'progress': 85,
                'icon': Icons.video_call_rounded,
              },
              {
                'title': 'Ortalama Puan',
                'value': '4.7/5.0',
                'change': '+0.2 vs Geçen Ay',
                'target': '4.8',
                'progress': 94,
                'icon': Icons.star_rounded,
              },
              {
                'title': 'Müşteri Memnuniyeti',
                'value': '89%',
                'change': '+5% vs Geçen Ay',
                'target': '95%',
                'progress': 94,
                'icon': Icons.thumb_up_rounded,
              },
              {
                'title': 'Yineleme Oranı',
                'value': '67%',
                'change': '+8% vs Geçen Ay',
                'target': '75%',
                'progress': 89,
                'icon': Icons.repeat_rounded,
              },
              {
                'title': 'Ortalama Seans Süresi',
                'value': '52 dk',
                'change': '+6 dk vs Geçen Ay',
                'target': '60 dk',
                'progress': 87,
                'icon': Icons.schedule_rounded,
              },
            ].map((kpi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                                  .withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              kpi['icon'] as IconData,
                              color: AppThemeColors.accentCyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kpi['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kpi['value'] as String,
                                  style: const TextStyle(
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
                                  kpi['change'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hedef: ${kpi['target']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (kpi['progress'] as int) / 100,
                          minHeight: 6,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            (kpi['progress'] as int) >= 85
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${kpi['progress']}% Hedefin Tamamlandı',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
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

class _GoalsTab extends ConsumerStatefulWidget {
  const _GoalsTab();

  @override
  ConsumerState<_GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<_GoalsTab> {
  late TextEditingController goalController;
  late TextEditingController targetController;

  @override
  void initState() {
    super.initState();
    goalController = TextEditingController();
    targetController = TextEditingController();
  }

  @override
  void dispose() {
    goalController.dispose();
    targetController.dispose();
    super.dispose();
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
              'İş Hedefleri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'title': 'Aylık Geliri ₺30,000\'e Çıkart',
                'progress': 82,
                'deadline': '31 Aralık 2026',
                'priority': 'Yüksek',
                'status': 'Üzerinde',
              },
              {
                'title': 'Puanlamayı 4.8\'e Yükselt',
                'progress': 94,
                'deadline': '30 Kasım 2026',
                'priority': 'Yüksek',
                'status': 'Üzerinde',
              },
              {
                'title': 'Aktif Müşteri Sayısını 200\'e Çıkart',
                'progress': 65,
                'deadline': '31 Mart 2027',
                'priority': 'Orta',
                'status': 'Izleme',
              },
              {
                'title': 'Yineleme Oranını %75\'e Çıkart',
                'progress': 89,
                'deadline': '31 Ocak 2027',
                'priority': 'Orta',
                'status': 'Üzerinde',
              },
            ].map((goal) {
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
                          Expanded(
                            child: Text(
                              goal['title'] as String,
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
                              color: goal['priority'] == 'Yüksek'
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.yellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              goal['priority'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: goal['priority'] == 'Yüksek'
                                    ? Colors.red
                                    : Colors.yellow,
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
                                  'İlerleme',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${goal['progress']}%',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Son Tarih',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  goal['deadline'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (goal['progress'] as int) / 100,
                          minHeight: 6,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                            AppThemeColors.accentCyan,
                          ),
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
                          goal['status'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text(
              'Yeni Hedef Oluştur',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalController,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Hedef adı',
                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Hedef değeri',
                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Hedef Ekle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geçmiş Sürüm Karşılaştırması (Ay)',
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProgressBar(height: 0.4, month: 'Oca', value: '16K'),
                      _ProgressBar(height: 0.5, month: 'Şub', value: '18.5K'),
                      _ProgressBar(height: 0.55, month: 'Mar', value: '19K'),
                      _ProgressBar(height: 0.65, month: 'Nis', value: '21K'),
                      _ProgressBar(height: 0.75, month: 'May', value: '24K'),
                      _ProgressBar(height: 0.82, month: 'Haz', value: '24.5K'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trend: Aylık gelir 50% artış gösterdi (Ocak → Haziran)',
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
              'Milestones (Dönüm Noktaları)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'title': 'İlk 100 Seans Tamamlandı',
                'date': '15 Şubat 2026',
                'status': 'Tamamlandı',
                'icon': Icons.check_circle_rounded,
              },
              {
                'title': 'İlk ₺10,000 Gelir',
                'date': '28 Mart 2026',
                'status': 'Tamamlandı',
                'icon': Icons.check_circle_rounded,
              },
              {
                'title': '4.7+ Puanlama Elde Edildi',
                'date': '12 Mayıs 2026',
                'status': 'Tamamlandı',
                'icon': Icons.check_circle_rounded,
              },
              {
                'title': 'Ayda 100+ Seans İçin Çalış',
                'date': '30 Haziran 2026',
                'status': 'Tamamlandı',
                'icon': Icons.check_circle_rounded,
              },
              {
                'title': 'İlk ₺20,000 Gelir Hedefi',
                'date': '15 Eylül 2026',
                'status': 'Tamamlandı',
                'icon': Icons.check_circle_rounded,
              },
              {
                'title': 'İlk ₺30,000 Gelir Hedefi',
                'date': '31 Aralık 2026',
                'status': 'Sürüyor...',
                'icon': Icons.schedule_rounded,
              },
            ].map((milestone) {
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
                  child: Row(
                    children: [
                      Icon(
                        milestone['icon'] as IconData,
                        color: milestone['status'] == 'Tamamlandı'
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              milestone['date'] as String,
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
                          color: milestone['status'] == 'Tamamlandı'
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          milestone['status'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: milestone['status'] == 'Tamamlandı'
                                ? Colors.green
                                : Colors.orange,
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.height,
    required this.month,
    required this.value,
  });

  final double height;
  final String month;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 120 * height,
          decoration: BoxDecoration(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          month,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
