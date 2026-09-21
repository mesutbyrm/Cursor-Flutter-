import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicRetentionAnalyticsScreen extends ConsumerStatefulWidget {
  const PsychicRetentionAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicRetentionAnalyticsScreen> createState() =>
      _PsychicRetentionAnalyticsScreenState();
}

class _PsychicRetentionAnalyticsScreenState
    extends ConsumerState<PsychicRetentionAnalyticsScreen>
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
            'Müşteri Bekletimi',
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
              Tab(text: 'Yaşam Değeri'),
              Tab(text: 'Churn Risk'),
              Tab(text: 'Kampanyalar'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _LifetimeValueTab(),
            _ChurnRiskTab(),
            _CampaignsTab(),
          ],
        ),
      ),
    );
  }
}

class _LifetimeValueTab extends StatefulWidget {
  @override
  State<_LifetimeValueTab> createState() => _LifetimeValueTabState();
}

class _LifetimeValueTabState extends State<_LifetimeValueTab> {
  late List<Map<String, dynamic>> customers;

  @override
  void initState() {
    super.initState();
    customers = [
      {
        'name': 'Emre Demir',
        'ltv': '₺2,850',
        'status': 'Yüksek Değer',
        'sessions': 45,
        'avgSpending': '₺63.33',
        'retention': 95,
      },
      {
        'name': 'Ayşe Kara',
        'ltv': '₺1,680',
        'status': 'Orta-Yüksek',
        'sessions': 28,
        'avgSpending': '₺60',
        'retention': 88,
      },
      {
        'name': 'Aslı Şahiner',
        'ltv': '₺1,452',
        'status': 'Orta-Yüksek',
        'sessions': 24,
        'avgSpending': '₺60.5',
        'retention': 85,
      },
      {
        'name': 'Zeynep Mert',
        'ltv': '₺960',
        'status': 'Orta',
        'sessions': 16,
        'avgSpending': '₺60',
        'retention': 72,
      },
      {
        'name': 'Fatma Yıldız',
        'ltv': '₺420',
        'status': 'Düşük',
        'sessions': 7,
        'avgSpending': '₺60',
        'retention': 45,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Müşteri Yaşam Değeri (LTV)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplam LTV',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '₺7,362',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppThemeColors.accentCyan,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ortalama Seans Başına',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₺60.67',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Seanslar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '120',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktif Müşteriler',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '5',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Müşteri Sıralaması',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...customers.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final customer = entry.value;
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$index',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.accentCyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(customer['status'])
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              customer['status'],
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(customer['status']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${customer["sessions"]} seans',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      customer['ltv'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 12, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          '${customer["retention"]}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Yüksek Değer':
        return Colors.amber;
      case 'Orta-Yüksek':
        return Colors.blue;
      case 'Orta':
        return Colors.purple;
      case 'Düşük':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}

class _ChurnRiskTab extends StatefulWidget {
  @override
  State<_ChurnRiskTab> createState() => _ChurnRiskTabState();
}

class _ChurnRiskTabState extends State<_ChurnRiskTab> {
  late List<Map<String, dynamic>> riskCustomers;

  @override
  void initState() {
    super.initState();
    riskCustomers = [
      {
        'name': 'Müge Şahin',
        'riskLevel': 'Yüksek',
        'daysInactive': 21,
        'lastSession': '3 hafta önce',
        'ltv': '₺450',
      },
      {
        'name': 'Nazlı Kılıç',
        'riskLevel': 'Yüksek',
        'daysInactive': 35,
        'lastSession': '5 hafta önce',
        'ltv': '₺320',
      },
      {
        'name': 'Burcu Şen',
        'riskLevel': 'Orta',
        'daysInactive': 14,
        'lastSession': '2 hafta önce',
        'ltv': '₺680',
      },
      {
        'name': 'Derya Tür',
        'riskLevel': 'Orta',
        'daysInactive': 9,
        'lastSession': '9 gün önce',
        'ltv': '₺520',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Churn Risk Müşteriler',
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
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Risk Uyarısı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '4 müşteri 2+ hafta içinde seans almadı',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...riskCustomers.map((customer) => Container(
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
                    customer['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer['riskLevel'] == 'Yüksek'
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      customer['riskLevel'],
                      style: TextStyle(
                        fontSize: 10,
                        color: customer['riskLevel'] == 'Yüksek'
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İnaktif Gün',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${customer["daysInactive"]} gün',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son Seans',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer['lastSession'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LTV',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer['ltv'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${customer["name"]} ye win-back kampanyası gönderiliyor',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Win-Back Gönder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
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

class _CampaignsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = [
      {
        'name': 'Geri Dön - Ekstra Bonus',
        'target': 'Churn Riski Yüksek',
        'offer': '%15 İndirim',
        'status': 'Aktif',
        'sent': 12,
        'converted': 3,
      },
      {
        'name': 'VIP Ekstra Seanslar',
        'target': 'Yüksek Değer Müşteriler',
        'offer': 'Ücretsiz Ek Seans',
        'status': 'Aktif',
        'sent': 15,
        'converted': 7,
      },
      {
        'name': 'Yeni Müşteri Karşılama',
        'target': 'İlk Seanslar',
        'offer': '%20 İlk Seans',
        'status': 'Aktif',
        'sent': 45,
        'converted': 18,
      },
      {
        'name': 'Referral Bonusu',
        'target': 'Tüm Müşteriler',
        'offer': '₺50 Bonus',
        'status': 'Tamamlandı',
        'sent': 120,
        'converted': 28,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Bekletim Kampanyaları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...campaigns.map((campaign) => Container(
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
                    child: Text(
                      campaign['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: campaign['status'] == 'Aktif'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      campaign['status'],
                      style: TextStyle(
                        fontSize: 10,
                        color: campaign['status'] == 'Aktif'
                            ? Colors.green
                            : Colors.grey,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign['target'],
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
                            color: AppThemeColors.accentCyan
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            campaign['offer'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppThemeColors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.send_rounded,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            '${campaign["sent"]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 2),
                          Text(
                            '${campaign["converted"]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                content: Text('Yeni kampanya oluşturuluyor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Kampanya'),
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
