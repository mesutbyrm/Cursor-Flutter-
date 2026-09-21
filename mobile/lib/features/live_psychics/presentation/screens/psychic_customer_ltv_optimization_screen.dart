import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicCustomerLtvOptimizationScreen extends ConsumerStatefulWidget {
  const PsychicCustomerLtvOptimizationScreen({super.key});

  @override
  ConsumerState<PsychicCustomerLtvOptimizationScreen> createState() =>
      _PsychicCustomerLtvOptimizationScreenState();
}

class _PsychicCustomerLtvOptimizationScreenState
    extends ConsumerState<PsychicCustomerLtvOptimizationScreen>
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
          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'Müşteri LTV Optimizasyonu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Segmentler'),
                      Tab(text: 'Upsell'),
                      Tab(text: 'Kampanyalar'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SegmentsTab(),
                      _UpsellTab(),
                      _CampaignsTab(),
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

class _SegmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final segments = [
      {
        'name': 'VIP Müşteriler',
        'count': 12,
        'avgLtv': '₺850',
        'totalLtv': '₺10,200',
        'churnRisk': 'Düşük',
        'color': Color(0xFFFFD54F),
        'icon': Icons.starBorder,
      },
      {
        'name': 'Premium Üyeler',
        'count': 45,
        'avgLtv': '₺520',
        'totalLtv': '₺23,400',
        'churnRisk': 'Düşük',
        'color': Color(0xFF81C784),
        'icon': Icons.star_rounded,
      },
      {
        'name': 'Düzenli Müşteriler',
        'count': 128,
        'avgLtv': '₺280',
        'totalLtv': '₺35,840',
        'churnRisk': 'Orta',
        'color': Color(0xFF4FC3F7),
        'icon': Icons.person_rounded,
      },
      {
        'name': 'Nadir Müşteriler',
        'count': 87,
        'avgLtv': '₺95',
        'totalLtv': '₺8,265',
        'churnRisk': 'Yüksek',
        'color': Color(0xFFEF9A9A),
        'icon': Icons.person_outline_rounded,
      },
      {
        'name': 'Risk Altında',
        'count': 23,
        'avgLtv': '₺45',
        'totalLtv': '₺1,035',
        'churnRisk': 'Kritik',
        'color': Color(0xFFEF5350),
        'icon': Icons.warning_amber_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müşteri Segmentleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...segments.map((s) {
            final color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                  color: color.withValues(alpha: 0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            s['icon'] as IconData,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text('${s['count']} kişi'),
                          backgroundColor: color.withValues(alpha: 0.2),
                          labelStyle: TextStyle(fontSize: 11, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ort. LTV',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['avgLtv'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam LTV',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['totalLtv'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Kayıp Riski',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['churnRisk'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Segmentasyon Özeti',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Toplam Müşteri', '295'),
                const SizedBox(height: 10),
                _buildSummaryRow('Toplam LTV', '₺78,740'),
                const SizedBox(height: 10),
                _buildSummaryRow('Ort. Müşteri LTV', '₺267'),
                const SizedBox(height: 10),
                _buildSummaryRow('Yüksek Değerli (%)', '19% (VIP+Premium)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _UpsellTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final opportunities = [
      {
        'title': 'Premium Paket Yükseltmesi',
        'targetSegment': 'Düzenli Müşteriler',
        'currentCount': 128,
        'targetedCount': 85,
        'estimatedGain': '₺4,250',
        'conversion': 66,
        'effort': 'Düşük',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Aylık Abonelik Programı',
        'targetSegment': 'Premium Üyeler',
        'currentCount': 45,
        'targetedCount': 35,
        'estimatedGain': '₺3,150',
        'conversion': 78,
        'effort': 'Orta',
        'icon': Icons.card_membership_rounded,
      },
      {
        'title': 'VIP Danışman Hizmeti',
        'targetSegment': 'Premium Üyeler',
        'currentCount': 45,
        'targetedCount': 12,
        'estimatedGain': '₺6,000',
        'conversion': 27,
        'effort': 'Yüksek',
        'icon': Icons.person_add_rounded,
      },
      {
        'title': 'Paket Kombinasyon İndirimi',
        'targetSegment': 'Düzenli Müşteriler',
        'currentCount': 128,
        'targetedCount': 110,
        'estimatedGain': '₺2,200',
        'conversion': 86,
        'effort': 'Düşük',
        'icon': Icons.discount_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upsell / Cross-Sell Fırsatları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...opportunities.map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            opp['icon'] as IconData,
                            color: AppThemeColors.accentPurple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opp['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opp['targetSegment'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potansiyel Kazanç',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opp['estimatedGain'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF66BB6A),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dönüşüm Oranı',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${opp['conversion']}%',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Çaba',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opp['effort'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kampanya başlatılıyor: ${opp['title']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Kampanya Başlat', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Toplam Potansiyel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF66BB6A).withValues(alpha: 0.3),
              ),
              color: Color(0xFF66BB6A).withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ek Kazanç Potansiyeli',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66BB6A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '₺15,600',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Ort. Dönüş Süresi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66BB6A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '6 ay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsTab extends StatefulWidget {
  @override
  State<_CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<_CampaignsTab> {
  late TextEditingController _campaignController;
  bool _emailSelected = true;
  bool _smsSelected = false;
  bool _pushSelected = true;

  @override
  void initState() {
    super.initState();
    _campaignController = TextEditingController();
  }

  @override
  void dispose() {
    _campaignController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = [
      {
        'name': 'Nadir Müşteri Geri Kazanma',
        'target': 'Nadir Müşteriler (87)',
        'sent': 87,
        'opened': 52,
        'converted': 8,
        'roi': '340%',
        'status': 'Aktif',
        'startDate': '5 gün önce',
      },
      {
        'name': 'VIP Eksklusif Teklif',
        'target': 'VIP Müşteriler (12)',
        'sent': 12,
        'opened': 11,
        'converted': 7,
        'roi': '580%',
        'status': 'Aktif',
        'startDate': '3 gün önce',
      },
      {
        'name': 'Premium Üye Tutma',
        'target': 'Premium Üyeler (45)',
        'sent': 45,
        'opened': 38,
        'converted': 12,
        'roi': '420%',
        'status': 'Tamamlandı',
        'startDate': '20 gün önce',
      },
      {
        'name': 'Risk Altında Müşteriler',
        'target': 'Risk Altında (23)',
        'sent': 23,
        'opened': 14,
        'converted': 2,
        'roi': '180%',
        'status': 'Tamamlandı',
        'startDate': '15 gün önce',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retansiyon Kampanyaları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...campaigns.map((c) {
            final isActive = (c['status'] as String) == 'Aktif';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
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
                                c['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['target'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive ? const Color(0xFF66BB6A).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            c['status'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? const Color(0xFF66BB6A) : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricColumn('Açılış', '${c['opened']}/${c['sent']} (${((c['opened'] as int) / (c['sent'] as int) * 100).toStringAsFixed(0)}%)'),
                        _buildMetricColumn('Dönüşüm', '${c['converted']} müşteri'),
                        _buildMetricColumn('ROI', c['roi'] as String),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c['startDate'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Yeni Kampanya Oluştur',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _campaignController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Kampanya adı (örn: Eylül Flash Sale)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCE93D8), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İletişim Kanal Seçimi',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _emailSelected,
                  onChanged: (v) => setState(() => _emailSelected = v ?? false),
                  title: const Text('E-posta', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: _smsSelected,
                  onChanged: (v) => setState(() => _smsSelected = v ?? false),
                  title: const Text('SMS', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: _pushSelected,
                  onChanged: (v) => setState(() => _pushSelected = v ?? false),
                  title: const Text('Push', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kampanya oluşturuluyor...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                _campaignController.clear();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Kampanya Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
