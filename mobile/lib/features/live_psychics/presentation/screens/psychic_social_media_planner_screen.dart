import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicSocialMediaPlannerScreen extends ConsumerStatefulWidget {
  const PsychicSocialMediaPlannerScreen({super.key});

  @override
  ConsumerState<PsychicSocialMediaPlannerScreen> createState() =>
      _PsychicSocialMediaPlannerScreenState();
}

class _PsychicSocialMediaPlannerScreenState
    extends ConsumerState<PsychicSocialMediaPlannerScreen>
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
                    'Sosyal Medya Planlayıcısı',
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
                      Tab(text: 'Takvim'),
                      Tab(text: 'Kitaplık'),
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
                      _CalendarTab(),
                      _LibraryTab(),
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

class _CalendarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plannedPosts = [
      {
        'date': '2026-09-21',
        'time': '09:00',
        'platform': 'Instagram',
        'content': 'Hafta sonunda kendine dikkat et 🔮',
        'status': 'Yayında',
        'icon': Icons.camera_alt_rounded,
      },
      {
        'date': '2026-09-22',
        'time': '14:30',
        'platform': 'TikTok',
        'content': 'Fal okuma ipuçları #shorts',
        'status': 'Planlandı',
        'icon': Icons.videocam_rounded,
      },
      {
        'date': '2026-09-23',
        'time': '19:00',
        'platform': 'Instagram',
        'content': 'Müşteri başarı hikâyesi',
        'status': 'Planlandı',
        'icon': Icons.image_rounded,
      },
      {
        'date': '2026-09-24',
        'time': '11:15',
        'platform': 'Twitter',
        'content': 'Günün tarotunuzu alın',
        'status': 'Planlandı',
        'icon': Icons.description_rounded,
      },
      {
        'date': '2026-09-25',
        'time': '16:45',
        'platform': 'LinkedIn',
        'content': 'Profesyonel danışmanlık hizmetleri',
        'status': 'Planlandı',
        'icon': Icons.business_rounded,
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
                    content: Text('Yeni gönderiye hazırlanıyor...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Gönderi Planla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu Ay Planlanan Gönderiler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...plannedPosts.map((p) {
            final isPublished = (p['status'] as String) == 'Yayında';
            final platformColor = _getPlatformColor(p['platform'] as String);

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
                            color: platformColor.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            p['icon'] as IconData,
                            color: platformColor,
                            size: 18,
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
                                    p['platform'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    p['date'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['time'] as String,
                                style: TextStyle(
                                  fontSize: 12,
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
                            color: isPublished ? Color(0xFF66BB6A).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            p['status'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPublished ? Color(0xFF66BB6A) : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p['content'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    if (!isPublished) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gönderi düzenleme modu açılıyor...')),
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
                                const SnackBar(content: Text('Gönderi yayınlandı!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: platformColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Yayınla', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Instagram':
        return const Color(0xFFE4405F);
      case 'TikTok':
        return const Color(0xFF000000);
      case 'Twitter':
        return const Color(0xFF1DA1F2);
      case 'LinkedIn':
        return const Color(0xFF0A66C2);
      default:
        return const Color(0xFF4FC3F7);
    }
  }
}

class _LibraryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contentTemplates = [
      {
        'title': 'Günün Tarot Kartı',
        'description': 'Günlük tarot okuma içeriği',
        'hashtags': '#tarot #falokuma #gününtarotu',
        'uses': 24,
        'icon': Icons.credit_card_rounded,
      },
      {
        'title': 'Müşteri Başarı Hikâyesi',
        'description': 'Memnun müşteri testimonisalleri',
        'hashtags': '#başarıhikayesi #müşterimemnun',
        'uses': 18,
        'icon': Icons.people_rounded,
      },
      {
        'title': 'İpuç & Teknik',
        'description': 'Fal okuma ipuçları ve teknikler',
        'hashtags': '#ipuçlar #faltekniği #eğitim',
        'uses': 31,
        'icon': Icons.lightbulb_rounded,
      },
      {
        'title': 'Kampanya Reklamı',
        'description': 'Promosyon ve teklif reklamları',
        'hashtags': '#kampanya #teklif #indirim',
        'uses': 12,
        'icon': Icons.volume_up_rounded,
      },
      {
        'title': 'Q&A Seansı',
        'description': 'Müşteri sorularına yanıtlar',
        'hashtags': '#soruvecevap #ssss #falsorulari',
        'uses': 9,
        'icon': Icons.question_answer_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İçerik Şablonları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...contentTemplates.map((t) {
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
                            t['icon'] as IconData,
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
                                t['title'] as String,
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
                        Chip(
                          label: Text('${t['uses']}x'),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t['hashtags'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4FC3F7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${t['title']} şablonuyla gönderi oluşturuluyor...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.accentCyan,
                          foregroundColor: Colors.black,
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
    final publishedPosts = [
      {
        'date': '2026-09-20',
        'platform': 'Instagram',
        'likes': 156,
        'comments': 23,
        'shares': 8,
        'engagement': '18.7%',
        'reach': '2.1K',
      },
      {
        'date': '2026-09-19',
        'platform': 'TikTok',
        'likes': 3240,
        'comments': 187,
        'shares': 456,
        'engagement': '42.3%',
        'reach': '45.2K',
      },
      {
        'date': '2026-09-18',
        'platform': 'Instagram',
        'likes': 234,
        'comments': 34,
        'shares': 12,
        'engagement': '22.1%',
        'reach': '3.8K',
      },
      {
        'date': '2026-09-17',
        'platform': 'Twitter',
        'likes': 89,
        'comments': 12,
        'shares': 4,
        'engagement': '8.5%',
        'reach': '1.2K',
      },
      {
        'date': '2026-09-16',
        'platform': 'LinkedIn',
        'likes': 45,
        'comments': 8,
        'shares': 2,
        'engagement': '5.3%',
        'reach': '620',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Yayımlanan Gönderiler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...publishedPosts.map((p) {
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
                              p['platform'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['date'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color(0xFF4FC3F7).withValues(alpha: 0.2),
                          ),
                          child: Text(
                            '${p['engagement']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEngagementMetric('Beğeni', '${p['likes']}', Icons.favorite_rounded, Color(0xFFFF4081)),
                        _buildEngagementMetric('Yorum', '${p['comments']}', Icons.comment_rounded, Color(0xFF29B6F6)),
                        _buildEngagementMetric('Paylaşım', '${p['shares']}', Icons.share_rounded, Color(0xFF66BB6A)),
                        _buildEngagementMetric('Reach', '${p['reach']}', Icons.visibility_rounded, Color(0xFFFFCA28)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Sosyal Medya Özeti',
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
                _buildSummaryRow('Toplam Yayınlanan', '286 gönderi'),
                const SizedBox(height: 10),
                _buildSummaryRow('Toplam Etkileşim', '51.2K'),
                const SizedBox(height: 10),
                _buildSummaryRow('Ort. Engagement Oranı', '19.4%'),
                const SizedBox(height: 10),
                _buildSummaryRow('Takipçi Artışı (30 gün)', '+1,240 yeni takipçi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
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
