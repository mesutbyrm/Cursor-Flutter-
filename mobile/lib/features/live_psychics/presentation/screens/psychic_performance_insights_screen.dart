import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/discover_background.dart';

class PsychicPerformanceInsightsScreen extends ConsumerStatefulWidget {
  const PsychicPerformanceInsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicPerformanceInsightsScreen> createState() =>
      _PsychicPerformanceInsightsScreenState();
}

class _PsychicPerformanceInsightsScreenState
    extends ConsumerState<PsychicPerformanceInsightsScreen>
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
            'Performans İçgörüleri',
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
              Tab(text: 'Metrikler'),
              Tab(text: 'Karşılaştırma'),
              Tab(text: 'Eğilimler'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _MetricsTab(),
            _ComparisonTab(),
            _TrendsTab(),
          ],
        ),
      ),
    );
  }
}

class _MetricsTab extends StatefulWidget {
  @override
  State<_MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<_MetricsTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Temel Metrikler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetricCard('Toplam Kazanç', '₺7,362', '+₺845 (+12.9%)', Colors.green),
        _buildMetricCard('Ortalama Puan', '4.8★', '+0.2 (+4.3%)', Colors.amber),
        _buildMetricCard('Aylık Seanslar', '120', '+25 (+26.3%)', Colors.blue),
        _buildMetricCard('Müşteri Dönüş Oranı', '82%', '+8% (+10.8%)', Colors.purple),
        const SizedBox(height: 16),
        const Text(
          'Haftalık Performans',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeekDay('Pzt', 8, 40),
                  _buildWeekDay('Sal', 12, 40),
                  _buildWeekDay('Çar', 10, 40),
                  _buildWeekDay('Per', 15, 40),
                  _buildWeekDay('Cum', 18, 40),
                  _buildWeekDay('Cmt', 22, 40),
                  _buildWeekDay('Paz', 20, 40),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bu Hafta: 105 seans',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  Text(
                    'Geçen Hafta: 92 seans',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color) {
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
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDay(String day, int height, int maxHeight) {
    return Column(
      children: [
        Container(
          width: 20,
          height: (height / maxHeight * 60).toDouble(),
          decoration: BoxDecoration(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$height',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _ComparisonTab extends StatefulWidget {
  @override
  State<_ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends State<_ComparisonTab> {
  late List<Map<String, dynamic>> comparisons;

  @override
  void initState() {
    super.initState();
    comparisons = [
      {
        'metric': 'Ortalama Puan',
        'you': 4.8,
        'category': 4.3,
        'status': 'İyi',
      },
      {
        'metric': 'Dönüş Oranı',
        'you': 82,
        'category': 68,
        'status': 'İyi',
      },
      {
        'metric': 'Yanıt Süresi (Saat)',
        'you': 2.1,
        'category': 4.5,
        'status': 'İyi',
      },
      {
        'metric': 'Seans Başına Kazanç',
        'you': 61.35,
        'category': 58.90,
        'status': 'Orta',
      },
      {
        'metric': 'Aylık Aktif Müşteri',
        'you': 12,
        'category': 8,
        'status': 'İyi',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kategori Karşılaştırması',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
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
                      'Siz Kategorinin Üzerinde',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '5 metrikte kategori ortalamasını geçtiniz',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...comparisons.map((comp) => Container(
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
                  Text(
                    comp['metric'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: comp['status'] == 'İyi'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      comp['status'],
                      style: TextStyle(
                        fontSize: 10,
                        color: comp['status'] == 'İyi'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (comp['you'] as num) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    comp['you'] > comp['category']
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Siz: ${comp["you"]}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Kategori: ${comp["category"]}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _TrendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trends = [
      {
        'title': 'Kazanç Trendi',
        'description': 'Son 3 ayda %28 artış',
        'trend': 'Artış',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Müşteri Memnuniyeti',
        'description': 'Puan 4.5 tan 4.8 e yükseldi',
        'trend': 'Artış',
        'icon': Icons.star_rate_rounded,
      },
      {
        'title': 'Yanıt Hızı',
        'description': '4.2 saatten 2.1 saate düştü',
        'trend': 'İyileşti',
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'Mevsimsel Talep',
        'description': 'Kış aylarında talep %15 artar',
        'trend': 'Mevsimsel',
        'icon': Icons.calendar_today_rounded,
      },
      {
        'title': 'Haftanın En Yoğun Günü',
        'description': 'Cumartesi ve Pazar en fazla seans',
        'trend': 'Sabit',
        'icon': Icons.event_note_rounded,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Performans Eğilimleri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...trends.map((trend) => Container(
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
                  color: _getTrendColor(trend['trend'] as String)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(trend['icon'] as IconData,
                    color: _getTrendColor(trend['trend'] as String),
                    size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trend['description'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTrendColor(trend['trend'] as String)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trend['trend'],
                  style: TextStyle(
                    fontSize: 10,
                    color: _getTrendColor(trend['trend'] as String),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )),
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
                      'Önerilir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Cumartesi/Pazar daha fazla seans açarak geliri artırabilirsiniz',
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

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Artış':
        return Colors.green;
      case 'İyileşti':
        return Colors.blue;
      case 'Mevsimsel':
        return Colors.orange;
      case 'Sabit':
        return Colors.cyan;
      default:
        return Colors.white;
    }
  }
}
