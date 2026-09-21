import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicCustomerChemistryScreen extends ConsumerStatefulWidget {
  const PsychicCustomerChemistryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicCustomerChemistryScreen> createState() =>
      _PsychicCustomerChemistryScreenState();
}

class _PsychicCustomerChemistryScreenState
    extends ConsumerState<PsychicCustomerChemistryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            'Müşteri Kimyası',
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
              Tab(text: 'Önerileri Gör'),
              Tab(text: 'Uyumluluk Analizi'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _RecommendationsTab(
              filterCategory: _filterCategory,
              onFilterChanged: (category) {
                setState(() => _filterCategory = category);
              },
            ),
            _CompatibilityAnalysisTab(),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsTab extends StatefulWidget {
  final String filterCategory;
  final Function(String) onFilterChanged;

  const _RecommendationsTab({
    required this.filterCategory,
    required this.onFilterChanged,
  });

  @override
  State<_RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<_RecommendationsTab> {
  late List<Map<String, dynamic>> recommendations;

  @override
  void initState() {
    super.initState();
    recommendations = [
      {
        'name': 'Ayla Kaya',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Ayla',
        'compatibility': 95,
        'reason': 'Tarot seansı tercih ediyor',
        'interests': ['Tarot', 'Gelecek', 'İlişkiler'],
        'previousSessions': 0,
        'budget': '₺500+',
        'lastActive': '2 saat önce',
        'status': 'Çok İyi Eşleşme',
        'statusColor': Colors.green,
      },
      {
        'name': 'Zeynep Demir',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Zeynep',
        'compatibility': 88,
        'reason': 'Astrolog danışmanı arıyor',
        'interests': ['Astroloji', 'Burç', 'Kişisel Gelişim'],
        'previousSessions': 2,
        'budget': '₺300+',
        'lastActive': '30 dakika önce',
        'status': 'İyi Eşleşme',
        'statusColor': const Color(0xFF4CAF50),
      },
      {
        'name': 'Fatma Üzüm',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Fatma',
        'compatibility': 78,
        'reason': 'Rehberlik seansı aradığı tespit edildi',
        'interests': ['Rehberlik', 'Kariyer', 'İlişkiler'],
        'previousSessions': 0,
        'budget': '₺250+',
        'lastActive': '4 saat önce',
        'status': 'Orta Eşleşme',
        'statusColor': Colors.orange,
      },
      {
        'name': 'Elif Çetin',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Elif',
        'compatibility': 72,
        'reason': 'Numeroloji analizi ilginç buluyor',
        'interests': ['Numeroloji', 'Ad Analizi', 'Geleceğin'],
        'previousSessions': 1,
        'budget': '₺200+',
        'lastActive': '1 saat önce',
        'status': 'Orta Eşleşme',
        'statusColor': Colors.orange,
      },
    ];
  }

  List<Map<String, dynamic>> get filteredRecommendations {
    if (widget.filterCategory == 'Tümü') return recommendations;
    return recommendations
        .where((r) => (r['interests'] as List).contains(widget.filterCategory))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tümü'),
              const SizedBox(width: 6),
              _buildFilterChip('Tarot'),
              const SizedBox(width: 6),
              _buildFilterChip('Astroloji'),
              const SizedBox(width: 6),
              _buildFilterChip('Rehberlik'),
              const SizedBox(width: 6),
              _buildFilterChip('Numeroloji'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filteredRecommendations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 48, color: Colors.white30),
                  const SizedBox(height: 12),
                  Text(
                    'Bu kategoride öneri yok',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredRecommendations
              .map((recommendation) => _buildRecommendationCard(recommendation)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = widget.filterCategory == label;
    return InkWell(
      onTap: () => widget.onFilterChanged(label),
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

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(recommendation['avatar']),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        recommendation['reason'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (recommendation['statusColor'] as Color)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${recommendation['compatibility']}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: recommendation['statusColor'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation['status'],
                    style: TextStyle(
                      fontSize: 10,
                      color: recommendation['statusColor'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            children: (recommendation['interests'] as List)
                .map(
                  (interest) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bütçe: ${recommendation['budget']}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  Text(
                    'Son Aktif: ${recommendation['lastActive']}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${recommendation['name']}\'e seans teklifi gönderildi'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Teklif Ver'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeColors.accentCyan,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompatibilityAnalysisTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profilinin Güçlü Yanları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          {
            'title': 'Tarot Uzmanı',
            'description': 'Tarot seansında %92 başarı oranı',
            'score': 92,
          },
          {
            'title': 'Astroloji Danışmanı',
            'description': 'Burç analizi ve müşteri memnuniyeti çok yüksek',
            'score': 88,
          },
          {
            'title': 'Rehberlik Koçu',
            'description': 'Yaşam yönlendirmede müşteri sadakati %95',
            'score': 95,
          },
        ].map((strength) => _buildStrengthCard(strength)),
        const SizedBox(height: 24),

        const Text(
          'Gelişme Alanları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          {
            'title': 'Numeroloji',
            'description': 'Bu alanda seansın yok, başlamayı düşün',
            'opportunity': 'Orta',
          },
          {
            'title': 'Kariyer Danışmanlığı',
            'description': 'Talep var ama az hizmet veriyorsun',
            'opportunity': 'Yüksek',
          },
        ].map((area) => _buildOpportunityCard(area)),
        const SizedBox(height: 24),

        const Text(
          'Müşteri Tiplerinin Dağılımı',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('İlişki Sorunları', 38),
          ('Kariyer Danışmanlığı', 28),
          ('Kişisel Gelişim', 20),
          ('Finans Danışmanlığı', 14),
        ].map((item) => _buildDistributionRow(item.$1, item.$2)),
        const SizedBox(height: 24),

        // Recommendation
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
              Icon(Icons.lightbulb_rounded,
                  color: AppThemeColors.accentCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uzman Tavsiyeleri',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Numeroloji seansı ekleyerek hedef müşteri tabanını 25% artıra bilirsin',
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

  Widget _buildStrengthCard(Map<String, dynamic> strength) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strength['title'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${strength['score']}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strength['description'],
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> area) {
    final opportunityColor = area['opportunity'] == 'Yüksek'
        ? Colors.orange
        : area['opportunity'] == 'Orta'
            ? Colors.yellow
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: opportunityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: opportunityColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                area['title'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: opportunityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  area['opportunity'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: opportunityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            area['description'],
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(String type, int percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.87)),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(
                AppThemeColors.accentCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
