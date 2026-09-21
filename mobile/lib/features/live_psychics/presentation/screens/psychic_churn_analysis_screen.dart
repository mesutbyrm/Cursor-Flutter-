import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicChurnAnalysisScreen extends ConsumerStatefulWidget {
  const PsychicChurnAnalysisScreen({super.key});

  @override
  ConsumerState<PsychicChurnAnalysisScreen> createState() =>
      _PsychicChurnAnalysisScreenState();
}

class _PsychicChurnAnalysisScreenState
    extends ConsumerState<PsychicChurnAnalysisScreen>
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
                              'Müşteri Kayıp Analizi',
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
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.trending_down_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kayıp Oranı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '8.2%',
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
                                  'Risk altında',
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
                                    '24 müşteri',
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
                    Tab(text: 'Risk Değerlendirmesi'),
                    Tab(text: 'Stratejiler'),
                    Tab(text: 'Analitikler'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _RiskAssessmentTab(),
                      _RetentionStrategiesTab(),
                      _ChurnAnalyticsTab(),
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

class _RiskAssessmentTab extends StatelessWidget {
  const _RiskAssessmentTab();

  @override
  Widget build(BuildContext context) {
    final atRiskCustomers = [
      {
        'name': 'Ayşe Yılmaz',
        'risk': 'Çok Yüksek',
        'riskColor': Colors.red,
        'lastSession': '45 gün önce',
        'sessionFreq': '↓ 85% azalma',
        'spent': '₺2,840',
        'reason': 'Uzun inaktivite',
      },
      {
        'name': 'Mehmet Kaya',
        'risk': 'Yüksek',
        'riskColor': Colors.orange,
        'lastSession': '28 gün önce',
        'sessionFreq': '↓ 62% azalma',
        'spent': '₺1,950',
        'reason': 'Düşük memnuniyet',
      },
      {
        'name': 'Fatma Demir',
        'risk': 'Orta',
        'riskColor': Colors.yellow,
        'lastSession': '18 gün önce',
        'sessionFreq': '↓ 40% azalma',
        'spent': '₺3,200',
        'reason': 'Fiyat hassasiyeti',
      },
      {
        'name': 'Ali Şahin',
        'risk': 'Yüksek',
        'riskColor': Colors.orange,
        'lastSession': '32 gün önce',
        'sessionFreq': '↓ 71% azalma',
        'spent': '₺1,620',
        'reason': 'Hizmet kalitesi',
      },
      {
        'name': 'Zeynep Ağlar',
        'risk': 'Çok Yüksek',
        'riskColor': Colors.red,
        'lastSession': '52 gün önce',
        'sessionFreq': '↓ 92% azalma',
        'spent': '₺2,100',
        'reason': 'Uzun inaktivite',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: atRiskCustomers.length,
      itemBuilder: (context, index) {
        final customer = atRiskCustomers[index];
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (customer['riskColor'] as Color)
                            .withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: customer['riskColor'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer['lastSession'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (customer['riskColor'] as Color)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        customer['risk'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: customer['riskColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        label: 'Seans Sıklığı',
                        value: customer['sessionFreq'] as String,
                        valueColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoItem(
                        label: 'Harcama',
                        value: customer['spent'] as String,
                        valueColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Neden: ${customer['reason']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.email_rounded, size: 16),
                        label: const Text('Mesaj Gönder'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.local_offer_rounded, size: 16),
                        label: const Text('İndirim Sunuş'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RetentionStrategiesTab extends ConsumerStatefulWidget {
  const _RetentionStrategiesTab();

  @override
  ConsumerState<_RetentionStrategiesTab> createState() =>
      _RetentionStrategiesTabState();
}

class _RetentionStrategiesTabState
    extends ConsumerState<_RetentionStrategiesTab> {
  String selectedStrategy = 'özel-indirim';

  @override
  Widget build(BuildContext context) {
    final strategies = [
      {
        'id': 'özel-indirim',
        'name': 'Özel İndirim Teklifi',
        'desc': 'İlk seansda %20 indirim sunma',
        'effectiveness': '67%',
        'impact': '+240 müşteri',
        'icon': Icons.local_offer_rounded,
      },
      {
        'id': 'kişisel-temas',
        'name': 'Kişisel Temas',
        'desc': 'Doğum günü mesajı ve özel teklif gönderme',
        'effectiveness': '74%',
        'impact': '+310 müşteri',
        'icon': Icons.mail_rounded,
      },
      {
        'id': 'vip-program',
        'name': 'VIP Program',
        'desc': 'Sadık müşterilere özel faydalar sunma',
        'effectiveness': '82%',
        'impact': '+420 müşteri',
        'icon': Icons.star_rounded,
      },
      {
        'id': 'paket-bundle',
        'name': 'Paket Bundle',
        'desc': 'Birden fazla seansı birlikte satma',
        'effectiveness': '71%',
        'impact': '+290 müşteri',
        'icon': Icons.inventory_2_rounded,
      },
      {
        'id': 'özel-içerik',
        'name': 'Özel İçerik',
        'desc': 'Seans dışı değerli içerik paylaşma',
        'effectiveness': '58%',
        'impact': '+180 müşteri',
        'icon': Icons.video_library_rounded,
      },
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Önerilen Strateji',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...strategies.asMap().entries.map((entry) {
              final strategy = entry.value;
              final isSelected = selectedStrategy == strategy['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => selectedStrategy = strategy['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppThemeColors.accentCyan.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppThemeColors.accentCyan.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (strategy['icon'] == Icons.star_rounded
                                    ? Colors.amber
                                    : AppThemeColors.accentCyan)
                                .withValues(alpha: 0.3),
                          ),
                          child: Icon(
                            strategy['icon'] as IconData,
                            color: strategy['icon'] == Icons.star_rounded
                                ? Colors.amber
                                : AppThemeColors.accentCyan,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strategy['name'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strategy['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              strategy['effectiveness'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strategy['impact'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            if (selectedStrategy.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Müdahale Şablonları',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    {
                      'name': 'Standart Müdahale',
                      'content': 'Sizi özledik! Sizin için özel bir teklif hazırladık...',
                    },
                    {
                      'name': 'Kişisel Temas',
                      'content':
                          'Merhaba [Ad]! Seanslarımızı nasıl buldunuz merak ediyorum...',
                    },
                  ].map((template) {
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
                            Text(
                              template['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              template['content'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Text(
                                'Kullan',
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
          ],
        ),
      ),
    );
  }
}

class _ChurnAnalyticsTab extends StatelessWidget {
  const _ChurnAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kayıp Trendi (12 Ay)',
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
                      _ChartBar(height: 0.4, month: 'Oca'),
                      _ChartBar(height: 0.5, month: 'Şub'),
                      _ChartBar(height: 0.45, month: 'Mar'),
                      _ChartBar(height: 0.65, month: 'Nis'),
                      _ChartBar(height: 0.7, month: 'May'),
                      _ChartBar(height: 0.85, month: 'Haz'),
                      _ChartBar(height: 0.75, month: 'Tem'),
                      _ChartBar(height: 0.8, month: 'Ağu'),
                      _ChartBar(height: 0.62, month: 'Eyl'),
                      _ChartBar(height: 0.55, month: 'Eki'),
                      _ChartBar(height: 0.52, month: 'Kas'),
                      _ChartBar(height: 0.48, month: 'Ara'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Yıllık ortalama kayıp oranı: 6.8%',
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
              'Kayıp Sebepleri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {
                'reason': 'Uzun İnaktivite',
                'percentage': 38,
                'count': '9 müşteri',
              },
              {
                'reason': 'Fiyat Hassasiyeti',
                'percentage': 22,
                'count': '5 müşteri',
              },
              {
                'reason': 'Hizmet Kalitesi',
                'percentage': 18,
                'count': '4 müşteri',
              },
              {
                'reason': 'Alternatif Hizmet',
                'percentage': 15,
                'count': '4 müşteri',
              },
              {
                'reason': 'Diğer',
                'percentage': 7,
                'count': '2 müşteri',
              },
            ].map((item) {
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
                              item['reason'] as String,
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
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.accentCyan
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item['percentage']}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppThemeColors.accentCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item['percentage'] as int) / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            item['percentage'] == 38
                                ? Colors.red
                                : item['percentage'] == 22
                                    ? Colors.orange
                                    : AppThemeColors.accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['count'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text(
              'Mevsimsel Örüntüler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              {'season': 'Kış', 'change': '+12% kayıp', 'icon': Icons.ac_unit},
              {'season': 'İlkbahar', 'change': '-8% kayıp', 'icon': Icons.eco},
              {'season': 'Yaz', 'change': '+15% kayıp', 'icon': Icons.wb_sunny},
              {
                'season': 'Sonbahar',
                'change': '-5% kayıp',
                'icon': Icons.cloud_rounded
              },
            ].map((season) {
              final isIncrease = (season['change'] as String).contains('+');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          season['icon'] as IconData,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          season['season'] as String,
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
                          color: isIncrease
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          season['change'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isIncrease ? Colors.red : Colors.green,
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

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.height, required this.month});

  final double height;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 100 * height,
          decoration: BoxDecoration(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
