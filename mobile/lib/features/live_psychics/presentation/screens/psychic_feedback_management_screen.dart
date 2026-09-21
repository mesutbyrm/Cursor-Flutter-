import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicFeedbackManagementScreen extends ConsumerStatefulWidget {
  const PsychicFeedbackManagementScreen({super.key});

  @override
  ConsumerState<PsychicFeedbackManagementScreen> createState() =>
      _PsychicFeedbackManagementScreenState();
}

class _PsychicFeedbackManagementScreenState
    extends ConsumerState<PsychicFeedbackManagementScreen>
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
                    'Geri Bildirim Yönetimi',
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
                      Tab(text: 'Geri Bildirimler'),
                      Tab(text: 'Şablonlar'),
                      Tab(text: 'Özet'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeedbacksTab(),
                      _TemplatesTab(),
                      _SummaryTab(),
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

class _FeedbacksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final feedbacks = [
      {
        'customer': 'Ayşe K.',
        'rating': 5,
        'date': '2026-09-20',
        'comment': 'Harika bir seans! Çok yardımcı oldu. Kesinlikle tekrar geleceğim.',
        'sentiment': 'Çok Pozitif',
        'category': 'Genel Memnuniyet',
      },
      {
        'customer': 'Mehmet D.',
        'rating': 4,
        'date': '2026-09-19',
        'comment': 'İyi bir seans oldu ama saat geç başladı.',
        'sentiment': 'Pozitif',
        'category': 'Zamanlama',
      },
      {
        'customer': 'Zeynep T.',
        'rating': 3,
        'date': '2026-09-18',
        'comment': 'Beklentiyi karşıladı fakat daha detaylı analiz olabilirdi.',
        'sentiment': 'Nötr',
        'category': 'Hizmet Kalitesi',
      },
      {
        'customer': 'Ali Y.',
        'rating': 5,
        'date': '2026-09-17',
        'comment': 'Mükemmel! Çok profesyonel ve empati kurucu bir danışman.',
        'sentiment': 'Çok Pozitif',
        'category': 'Profesyonellik',
      },
      {
        'customer': 'Funda M.',
        'rating': 2,
        'date': '2026-09-16',
        'comment': 'Seansın kalitesi beklentiyi karşılamadı.',
        'sentiment': 'Negatif',
        'category': 'Hizmet Kalitesi',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alınan Geri Bildirimler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...feedbacks.map((f) {
            final rating = f['rating'] as int;
            final sentiment = f['sentiment'] as String;
            final sentimentColor = sentiment == 'Çok Pozitif' ? Color(0xFF66BB6A) :
                                   sentiment == 'Pozitif' ? Color(0xFF81C784) :
                                   sentiment == 'Nötr' ? Color(0xFFFFD54F) :
                                   Color(0xFFEF5350);

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['customer'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f['date'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: index < rating ? const Color(0xFFFFD54F) : Colors.white.withValues(alpha: 0.3),
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      f['comment'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: sentimentColor.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            sentiment,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: sentimentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            f['category'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${f['customer']} müşterisine yanıt yazılıyor...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text('Yanıt Ver', style: TextStyle(fontSize: 11)),
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

class _TemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'name': 'Genel Memnuniyet',
        'questions': [
          'Seansınızdan memnun oldunuz mu?',
          'Danışman size yeterince dikkat etti mi?',
          'Hizmetin kalitesi beklentiyi karşıladı mı?',
          'Tekrar gelmek ister misiniz?',
        ],
        'usage': 87,
      },
      {
        'name': 'Seans Detaylı Değerlendirme',
        'questions': [
          'Danışmanın profesyonelliğini nasıl değerlendirirsiniz?',
          'Çalışılan konular net açıklandı mı?',
          'Tavsiyeler pratik ve uygulanabilir mi?',
          'Zamanlama uygun mudur?',
        ],
        'usage': 45,
      },
      {
        'name': 'İyileştirme Önerileri',
        'questions': [
          'Neyi iyileştirebilirim?',
          'Eksik gördüğünüz alanlar neler?',
          'Farklı hizmetler isteyebileceğiniz konular?',
          'Genel önerileriniz var mı?',
        ],
        'usage': 32,
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
                    content: Text('Yeni anket şablonu oluşturuluyor...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Şablon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Anket Şablonları',
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            t['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text('${t['usage']}x'),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...(t['questions'] as List).cast<String>().map((q) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $q',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${t['name']} şablonu düzenleniyor...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Düzenle', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${t['name']} şablonu paylaşılıyor...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeColors.accentPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Paylaş', style: TextStyle(fontSize: 11)),
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
}

class _SummaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geri Bildirim Özeti',
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
                _buildSummaryRow('Toplam Geri Bildirim', '134'),
                const SizedBox(height: 10),
                _buildSummaryRow('Ort. Puan', '4.3 / 5.0 ⭐'),
                const SizedBox(height: 10),
                _buildSummaryRow('Memnuniyet Oranı', '84%'),
                const SizedBox(height: 10),
                _buildSummaryRow('Yanıt Verme Oranı', '76%'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Duygu Analizi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            {'sentiment': 'Çok Pozitif', 'percent': 56, 'color': Color(0xFF66BB6A), 'count': '75'},
            {'sentiment': 'Pozitif', 'percent': 28, 'color': Color(0xFF81C784), 'count': '37'},
            {'sentiment': 'Nötr', 'percent': 12, 'color': Color(0xFFFFD54F), 'count': '16'},
            {'sentiment': 'Negatif', 'percent': 4, 'color': Color(0xFFEF5350), 'count': '6'},
          ].map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                        Text(
                          s['sentiment'] as String,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${s['count']} (${s['percent']}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: s['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (s['percent'] as int) / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          s['color'] as Color,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Kategori Analizi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            {'category': 'Genel Memnuniyet', 'score': '4.6/5.0', 'icon': Icons.sentiment_very_satisfied_rounded},
            {'category': 'Profesyonellik', 'score': '4.5/5.0', 'icon': Icons.work_rounded},
            {'category': 'Hizmet Kalitesi', 'score': '4.1/5.0', 'icon': Icons.check_circle_rounded},
            {'category': 'Zamanlama', 'score': '4.2/5.0', 'icon': Icons.schedule_rounded},
          ].map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Row(
                  children: [
                    Icon(
                      c['icon'] as IconData,
                      color: AppThemeColors.accentCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c['category'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color(0xFF66BB6A).withValues(alpha: 0.2),
                      ),
                      child: Text(
                        c['score'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF66BB6A),
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
