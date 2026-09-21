import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/discover_background.dart';
import 'package:canlifal_social/core/widgets/discover_tab_layout.dart';

class PsychicRatingSystemScreen extends ConsumerStatefulWidget {
  const PsychicRatingSystemScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicRatingSystemScreen> createState() =>
      _PsychicRatingSystemScreenState();
}

class _PsychicRatingSystemScreenState
    extends ConsumerState<PsychicRatingSystemScreen>
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
            'Puanlamalarım',
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
              Tab(text: 'İncelemeler'),
              Tab(text: 'İstatistikler'),
              Tab(text: 'Yanıtlar'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ReviewsTab(),
            _StatisticsTab(),
            _ResponsesTab(),
          ],
        ),
      ),
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  late List<Map<String, dynamic>> reviews;
  String _filterRating = 'all';

  @override
  void initState() {
    super.initState();
    reviews = [
      {
        'id': '1',
        'customerName': 'Ayşe K.',
        'customerAvatar':
            'https://api.dicebear.com/7.x/avataaars/svg?seed=Ayse',
        'rating': 5.0,
        'date': '2024-01-20',
        'comment':
            'Çok doğru bir seans yaptu. Tavsiyelerinin çoğu gerçekleşti!',
        'category': 'Accuracy',
        'hasResponse': false,
        'sessionType': 'Tarot',
      },
      {
        'id': '2',
        'customerName': 'Mehmet S.',
        'customerAvatar':
            'https://api.dicebear.com/7.x/avataaars/svg?seed=Mehmet',
        'rating': 4.0,
        'date': '2024-01-18',
        'comment': 'İyi bir danışman, çok profesyonel. Biraz daha detay beklerdim.',
        'category': 'Communication',
        'hasResponse': true,
        'responseText':
            'Teşekkür ederim! Sonraki seansımızda daha fazla ayrıntı paylaşacağım.',
        'sessionType': 'Numeroloji',
      },
      {
        'id': '3',
        'customerName': 'Zeynep M.',
        'customerAvatar':
            'https://api.dicebear.com/7.x/avataaars/svg?seed=Zeynep',
        'rating': 5.0,
        'date': '2024-01-15',
        'comment': 'Harika bir seans, çok sayılı ipuçları verdi. Tekrar geleceğim!',
        'category': 'Professionalism',
        'hasResponse': false,
        'sessionType': 'Astroloji',
      },
      {
        'id': '4',
        'customerName': 'Ali T.',
        'customerAvatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Ali',
        'rating': 3.0,
        'date': '2024-01-12',
        'comment': 'Orta seviye. Beklediğim kadar derinlemesine değildi.',
        'category': 'Accuracy',
        'hasResponse': false,
        'sessionType': 'Tarot',
      },
      {
        'id': '5',
        'customerName': 'Fatma D.',
        'customerAvatar':
            'https://api.dicebear.com/7.x/avataaars/svg?seed=Fatma',
        'rating': 5.0,
        'date': '2024-01-10',
        'comment': 'Çok duygusal ve yardımcı bir danışman. Çok teşekkürler!',
        'category': 'Empathy',
        'hasResponse': false,
        'sessionType': 'Rehberlik',
      },
    ];
  }

  List<Map<String, dynamic>> get filteredReviews {
    if (_filterRating == 'all') return reviews;
    final rating = int.tryParse(_filterRating) ?? 0;
    return reviews.where((r) => r['rating'].toInt() == rating).toList();
  }

  void _showResponseDialog(Map<String, dynamic> review) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(review['customerAvatar']),
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['customerName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: i < review['rating'].toInt()
                                    ? Colors.amber
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review['comment'],
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yanıtınız',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: responseController,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Müşterinize yanıt yazın...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text('İptal', style: TextStyle(fontSize: 13)),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (responseController.text.isNotEmpty) {
                          setState(() {
                            final idx = reviews.indexWhere(
                                (r) => r['id'] == review['id']);
                            if (idx != -1) {
                              reviews[idx]['hasResponse'] = true;
                              reviews[idx]['responseText'] =
                                  responseController.text;
                            }
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Yanıt gönderildi'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentCyan,
                      ),
                      child: const Text('Gönder',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('⭐⭐⭐⭐⭐', '5'),
                const SizedBox(width: 6),
                _buildFilterChip('⭐⭐⭐⭐', '4'),
                const SizedBox(width: 6),
                _buildFilterChip('⭐⭐⭐', '3'),
                const SizedBox(width: 6),
                _buildFilterChip('⭐⭐', '2'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredReviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.star_border_rounded,
                      size: 48, color: Colors.white30),
                  const SizedBox(height: 12),
                  Text(
                    'İnceleme bulunamadı',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredReviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterRating == value;
    return InkWell(
      onTap: () => setState(() => _filterRating = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppThemeColors.accentCyan
                : Colors.white.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppThemeColors.accentCyan : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(review['customerAvatar']),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        review['sessionType'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                review['date'],
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 16,
                  color: i < review['rating'].toInt() ? Colors.amber : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${review['rating'].toStringAsFixed(1)} / 5.0',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getCategoryColor(review['category']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  review['category'],
                  style: TextStyle(
                    fontSize: 10,
                    color: _getCategoryColor(review['category']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['comment'],
            style: const TextStyle(fontSize: 13, color: Colors.white87),
          ),
          if (review['hasResponse']) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: AppThemeColors.accentCyan),
                      const SizedBox(width: 6),
                      const Text(
                        'Sizin yanıtınız:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['responseText'],
                    style: const TextStyle(fontSize: 12, color: Colors.white87),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showResponseDialog(review),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Yanıt Ver'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Accuracy':
        return Colors.blue;
      case 'Professionalism':
        return Colors.purple;
      case 'Communication':
        return Colors.green;
      case 'Empathy':
        return Colors.pink;
      default:
        return Colors.cyan;
    }
  }
}

class _StatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = {
      'averageRating': 4.6,
      'totalReviews': 128,
      'ratingBreakdown': {5: 85, 4: 32, 3: 8, 2: 2, 1: 1},
      'categoryScores': {
        'Accuracy': 4.8,
        'Professionalism': 4.7,
        'Communication': 4.5,
        'Empathy': 4.9,
      },
      'thisMonth': 24,
      'trend': '+2.3%',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Rating
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentCyan.withValues(alpha: 0.2),
                AppThemeColors.accentPurple.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'Genel Puanı',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats['averageRating']}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 18,
                      color: i < (stats['averageRating'] as double).toInt()
                          ? Colors.amber
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${stats['totalReviews']} inceleme • Bu ay ${stats['thisMonth']}',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rating Distribution
        const Text(
          'Puan Dağılımı',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = (stats['ratingBreakdown'] as Map)[rating];
          final total = (stats['ratingBreakdown'] as Map).values
              .reduce((a, b) => a + b);
          final percentage = ((count as int) / (total as int) * 100).toInt();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 12,
                        color: i < rating ? Colors.amber : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$rating yıldız',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const Spacer(),
                    Text('$count ($percentage%)',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      _getRatingColor(rating),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Category Scores
        const Text(
          'Kategori Puanları',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...(stats['categoryScores'] as Map).entries.map((entry) {
          final category = entry.key as String;
          final score = entry.value as double;
          final colors = [
            Colors.blue,
            Colors.purple,
            Colors.green,
            Colors.pink,
          ];
          final categoryColors = {
            'Accuracy': Colors.blue,
            'Professionalism': Colors.purple,
            'Communication': Colors.green,
            'Empathy': Colors.pink,
          };

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: Colors.white87),
                ),
                Row(
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: categoryColors[category],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: score / 5,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          categoryColors[category],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Trend
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bu ayın puanı geçen aya göre artışta',
                  style: TextStyle(fontSize: 12, color: Colors.white87),
                ),
              ),
              Text(
                stats['trend'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.cyan;
      case 3:
        return Colors.yellow;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

class _ResponsesTab extends StatefulWidget {
  @override
  State<_ResponsesTab> createState() => _ResponsesTabState();
}

class _ResponsesTabState extends State<_ResponsesTab> {
  late List<Map<String, dynamic>> responses;

  @override
  void initState() {
    super.initState();
    responses = [
      {
        'id': '1',
        'customerName': 'Mehmet S.',
        'customerAvatar':
            'https://api.dicebear.com/7.x/avataaars/svg?seed=Mehmet',
        'originalReview': 'İyi bir danışman, çok profesyonel.',
        'originalRating': 4.0,
        'yourResponse': 'Teşekkür ederim! Sonraki seansımızda daha fazla ayrıntı paylaşacağım.',
        'responseDate': '2024-01-19',
        'customerReplyDate': null,
        'customerReply': null,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (responses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.message_outlined, size: 48, color: Colors.white30),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz yanıt vermediniz',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...responses.map((response) => _buildResponseCard(response)),
      ],
    );
  }

  Widget _buildResponseCard(Map<String, dynamic> response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(response['customerAvatar']),
                radius: 18,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response['customerName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    response['responseDate'],
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Müşterinin İncelemesi',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              response['originalReview'],
              style: const TextStyle(fontSize: 12, color: Colors.white87),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sizin Yanıtınız',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              response['yourResponse'],
              style: const TextStyle(fontSize: 12, color: Colors.white87),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yanıt silinecek'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Yanıtı Sil'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
