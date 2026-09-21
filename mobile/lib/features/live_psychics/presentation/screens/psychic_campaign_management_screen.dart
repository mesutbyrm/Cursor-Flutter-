import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicCampaignManagementScreen extends ConsumerStatefulWidget {
  const PsychicCampaignManagementScreen({super.key});

  @override
  ConsumerState<PsychicCampaignManagementScreen> createState() =>
      _PsychicCampaignManagementScreenState();
}

class _PsychicCampaignManagementScreenState
    extends ConsumerState<PsychicCampaignManagementScreen>
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
                    'Kampanya Yönetimi',
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
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Kampanyalar'),
                      Tab(text: 'Şablonlar'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _CampaignsTab(),
                      _TemplatesTab(),
                      _AnalyticsTab(),
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

class _CampaignsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campaigns = [
      {
        'name': 'Eylül Flash Sale',
        'status': 'Aktif',
        'startDate': '2026-09-15',
        'endDate': '2026-09-30',
        'audience': '156 kişi',
        'sent': 156,
        'opened': 89,
        'ctr': '32%',
        'conversions': 18,
        'revenue': '₺1,530',
        'icon': Icons.flash,
      },
      {
        'name': 'Premium Upgrade Önerisi',
        'status': 'Aktif',
        'startDate': '2026-09-10',
        'endDate': '2026-10-10',
        'audience': '45 kişi',
        'sent': 45,
        'opened': 38,
        'ctr': '68%',
        'conversions': 12,
        'revenue': '₺3,120',
        'icon': Icons.star_rounded,
      },
      {
        'name': 'Nadir Müşteri Geri Kazanma',
        'status': 'Taslak',
        'startDate': 'Planlanmamış',
        'endDate': 'Planlanmamış',
        'audience': '87 kişi',
        'sent': 0,
        'opened': 0,
        'ctr': '-',
        'conversions': 0,
        'revenue': '₺0',
        'icon': Icons.restore_rounded,
      },
      {
        'name': 'Ağustos Başarı Kampanyası',
        'status': 'Tamamlandı',
        'startDate': '2026-08-01',
        'endDate': '2026-08-31',
        'audience': '200 kişi',
        'sent': 200,
        'opened': 134,
        'ctr': '42%',
        'conversions': 28,
        'revenue': '₺2,380',
        'icon': Icons.check_circle_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yeni kampanya oluşturma ekranına yönlendiriliyorsunuz...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Kampanya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tüm Kampanyalar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...campaigns.map((c) {
            final isActive = (c['status'] as String) == 'Aktif';
            final isDraft = (c['status'] as String) == 'Taslak';
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
                            color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            c['icon'] as IconData,
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
                                c['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c['startDate']} — ${c['endDate']}',
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
                            color: isActive ? const Color(0xFF66BB6A).withValues(alpha: 0.2) :
                                   isDraft ? Colors.white.withValues(alpha: 0.1) :
                                   Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            c['status'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? const Color(0xFF66BB6A) :
                                     isDraft ? Colors.white.withValues(alpha: 0.6) :
                                     Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((c['sent'] as int) > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricColumn('Gönderilen', '${c['sent']}'),
                          _buildMetricColumn('Açılış', '${c['opened']} (${c['ctr']})'),
                          _buildMetricColumn('Dönüşüm', '${c['conversions']}'),
                          _buildMetricColumn('Gelir', c['revenue'] as String),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: Text(
                          'Henüz başlanmadı',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isDraft) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kampanya başlatıldı')),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                            label: const Text('Başlat'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Düzenle'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'name': 'Hoşgeldin Paketi',
        'description': 'Yeni müşteriler için ilk seans indirimi',
        'preview': 'Seni bekliyoruz! İlk seansında %20 indirim kazan',
        'uses': 34,
        'icon': Icons.card_giftcard_rounded,
      },
      {
        'name': 'Premium Upgrade',
        'description': 'Düzenli müşteriler için yükseltme teklifi',
        'preview': 'Premium üyeliğe geç, daha fazla tasarruf et',
        'uses': 12,
        'icon': Icons.star_rounded,
      },
      {
        'name': 'Geri Dön Kampanyası',
        'description': 'Hareketsiz müşteriler için retansiyon',
        'preview': 'Özledik seni! Özel teklifimiz bekliyorum',
        'uses': 8,
        'icon': Icons.restore_rounded,
      },
      {
        'name': 'Referral Bonusu',
        'description': 'Arkadaş davet etme ve bonus kazan',
        'preview': 'Arkadaşlarını davet et, ₺100 bonus kazan',
        'uses': 5,
        'icon': Icons.people_alt_rounded,
      },
      {
        'name': 'Paket Kombinasyonu',
        'description': 'Çoklu seans paketi indirimi',
        'preview': '5 seans paketinde %15 indirim fırsatı',
        'uses': 23,
        'icon': Icons.discount_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hazır Şablonlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...templates.map((t) {
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
                            t['icon'] as IconData,
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
                                t['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t['description'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${t['uses']}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Text(
                        t['preview'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${t['name']} şablonuyla kampanya başlatılıyor...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Şablonu Kullan', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final abTests = [
      {
        'name': 'Başlık A vs B Testi',
        'variantA': 'Seni İlk Seansında Bekliyoruz',
        'variantB': 'Özel İndirim Teklifim Var',
        'aOpened': 45,
        'bOpened': 52,
        'aConverted': 6,
        'bConverted': 9,
        'winner': 'B',
        'status': 'Tamamlandı',
      },
      {
        'name': 'Gönderme Saati Testi',
        'variantA': 'Sabah 09:00',
        'variantB': 'Akşam 19:00',
        'aOpened': 38,
        'bOpened': 61,
        'aConverted': 4,
        'bConverted': 11,
        'winner': 'B',
        'status': 'Tamamlandı',
      },
      {
        'name': 'CTA Butonu Testi',
        'variantA': 'Seans Rezerve Et',
        'variantB': 'Hemen Başla',
        'aOpened': 89,
        'bOpened': 87,
        'aConverted': 15,
        'bConverted': 13,
        'winner': 'A',
        'status': 'Tamamlandı',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A/B Test Sonuçları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...abTests.map((test) {
            final aConversionRate = ((test['aConverted'] as int) / (test['aOpened'] as int) * 100).toStringAsFixed(1);
            final bConversionRate = ((test['bConverted'] as int) / (test['bOpened'] as int) * 100).toStringAsFixed(1);
            final isWinnerA = (test['winner'] as String) == 'A';

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
                                test['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                test['status'] as String,
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
                            color: Color(0xFF66BB6A).withValues(alpha: 0.2),
                          ),
                          child: Text(
                            'Kazanan: ${test['winner']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF66BB6A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Varyant A',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isWinnerA ? const Color(0xFF66BB6A) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                test['variantA'] as String,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Açılış: ${test['aOpened']}, Dönüşüm: $aConversionRate%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Varyant B',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: !isWinnerA ? const Color(0xFF66BB6A) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                test['variantB'] as String,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Açılış: ${test['bOpened']}, Dönüşüm: $bConversionRate%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
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
            'Kampanya Özeti Metrikleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Toplam Gönderilen', '847'),
                const SizedBox(height: 10),
                _buildSummaryRow('Ort. Açılış Oranı', '52%'),
                const SizedBox(height: 10),
                _buildSummaryRow('Ort. Dönüşüm Oranı', '4.2%'),
                const SizedBox(height: 10),
                _buildSummaryRow('Toplam Gelir', '₺7,030'),
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
