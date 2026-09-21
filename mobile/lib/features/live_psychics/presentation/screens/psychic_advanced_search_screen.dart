import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicAdvancedSearchScreen extends ConsumerStatefulWidget {
  const PsychicAdvancedSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicAdvancedSearchScreen> createState() =>
      _PsychicAdvancedSearchScreenState();
}

class _PsychicAdvancedSearchScreenState
    extends ConsumerState<PsychicAdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _selectedFilter = 'Tümü';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            'Gelişmiş Arama',
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
              Tab(text: 'Müşteriler'),
              Tab(text: 'Seanslar'),
              Tab(text: 'Kayıtlı Filtreler'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _CustomersSearchTab(
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              dateRange: _dateRange,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
              onDateRangeChanged: (range) =>
                  setState(() => _dateRange = range),
            ),
            _SessionsSearchTab(
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              dateRange: _dateRange,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
              onDateRangeChanged: (range) =>
                  setState(() => _dateRange = range),
            ),
            _SavedFiltersTab(),
          ],
        ),
      ),
    );
  }
}

class _CustomersSearchTab extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedFilter;
  final DateTimeRange? dateRange;
  final Function(String) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;

  const _CustomersSearchTab({
    required this.searchController,
    required this.selectedFilter,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  });

  @override
  State<_CustomersSearchTab> createState() => _CustomersSearchTabState();
}

class _CustomersSearchTabState extends State<_CustomersSearchTab> {
  late List<Map<String, dynamic>> searchResults;
  late List<Map<String, dynamic>> filteredResults;

  @override
  void initState() {
    super.initState();
    searchResults = [
      {
        'name': 'Ayşe Kara',
        'lastSession': '2 gün önce',
        'sessions': 12,
        'rating': 4.8,
        'spent': '₺450',
        'status': 'Aktif',
        'favorite': true,
      },
      {
        'name': 'Zeynep Mert',
        'lastSession': '5 gün önce',
        'sessions': 8,
        'rating': 4.5,
        'spent': '₺320',
        'status': 'Aktif',
        'favorite': false,
      },
      {
        'name': 'Fatma Yıldız',
        'lastSession': '1 haftadır',
        'sessions': 5,
        'rating': 4.9,
        'spent': '₺280',
        'status': 'Uzun süredir beklemede',
        'favorite': true,
      },
      {
        'name': 'Müge Şahin',
        'lastSession': '3 haftadır',
        'sessions': 3,
        'rating': 4.2,
        'spent': '₺150',
        'status': 'İnaktif',
        'favorite': false,
      },
      {
        'name': 'Emre Demir',
        'lastSession': '1 gün önce',
        'sessions': 15,
        'rating': 5.0,
        'spent': '₺680',
        'status': 'Aktif',
        'favorite': true,
      },
    ];
    filteredResults = searchResults;
  }

  void _performSearch(String query) {
    final results = searchResults.where((item) {
      final matchesQuery = item['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());

      if (widget.selectedFilter == 'Aktif') {
        return matchesQuery && item['status'] == 'Aktif';
      } else if (widget.selectedFilter == 'Favori') {
        return matchesQuery && item['favorite'] == true;
      } else if (widget.selectedFilter == 'Yüksek Harcama') {
        return matchesQuery && item['spent'].toString().contains('₺');
      }
      return matchesQuery;
    }).toList();

    setState(() => filteredResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: widget.searchController,
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Müşteri adını ara...',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppThemeColors.accentCyan),
            suffixIcon: widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppThemeColors.accentCyan),
                    onPressed: () {
                      widget.searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppThemeColors.accentCyan, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tümü'),
              const SizedBox(width: 8),
              _buildFilterChip('Aktif'),
              const SizedBox(width: 8),
              _buildFilterChip('Favori'),
              const SizedBox(width: 8),
              _buildFilterChip('Yüksek Harcama'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Arama Sonuçları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (filteredResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 48, color: Colors.white54),
                const SizedBox(height: 12),
                Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...filteredResults.map((customer) => _buildCustomerCard(customer)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = widget.selectedFilter == label;
    return GestureDetector(
      onTap: () => widget.onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
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
            color: isSelected ? AppThemeColors.accentCyan : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer['name'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (customer['favorite'])
                          const Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customer['status'] == 'Aktif'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        customer['status'],
                        style: TextStyle(
                          fontSize: 10,
                          color: customer['status'] == 'Aktif'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        customer['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customer["sessions"]} seans',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son seans: ${customer["lastSession"]}',
                style: TextStyle(fontSize: 10, color: Colors.white54),
              ),
              Text(
                'Harcama: ${customer["spent"]}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppThemeColors.accentCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionsSearchTab extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedFilter;
  final DateTimeRange? dateRange;
  final Function(String) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;

  const _SessionsSearchTab({
    required this.searchController,
    required this.selectedFilter,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  });

  @override
  State<_SessionsSearchTab> createState() => _SessionsSearchTabState();
}

class _SessionsSearchTabState extends State<_SessionsSearchTab> {
  late List<Map<String, dynamic>> allSessions;
  late List<Map<String, dynamic>> filteredSessions;

  @override
  void initState() {
    super.initState();
    allSessions = [
      {
        'customer': 'Ayşe Kara',
        'type': 'Tarot',
        'date': '2026-09-20',
        'duration': '25 min',
        'amount': '₺75',
        'status': 'Tamamlandı',
      },
      {
        'customer': 'Zeynep Mert',
        'type': 'Astroloji',
        'date': '2026-09-19',
        'duration': '40 min',
        'amount': '₺120',
        'status': 'Tamamlandı',
      },
      {
        'customer': 'Emre Demir',
        'type': 'Rehberlik',
        'date': '2026-09-18',
        'duration': '35 min',
        'amount': '₺105',
        'status': 'Tamamlandı',
      },
      {
        'customer': 'Müge Şahin',
        'type': 'Numeroloji',
        'date': '2026-09-17',
        'duration': '30 min',
        'amount': '₺90',
        'status': 'İptal',
      },
      {
        'customer': 'Fatma Yıldız',
        'type': 'Tarot',
        'date': '2026-09-16',
        'duration': '45 min',
        'amount': '₺135',
        'status': 'Tamamlandı',
      },
    ];
    filteredSessions = allSessions;
  }

  void _performSearch(String query) {
    final results = allSessions.where((session) {
      final matchesQuery = session['customer']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());

      if (widget.selectedFilter == 'Tamamlandı') {
        return matchesQuery && session['status'] == 'Tamamlandı';
      } else if (widget.selectedFilter == 'İptal') {
        return matchesQuery && session['status'] == 'İptal';
      } else if (widget.selectedFilter == 'Tarot') {
        return matchesQuery && session['type'] == 'Tarot';
      }
      return matchesQuery;
    }).toList();

    setState(() => filteredSessions = results);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: widget.searchController,
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Müşteri adı veya tür ara...',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppThemeColors.accentCyan),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppThemeColors.accentCyan, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tümü'),
              const SizedBox(width: 8),
              _buildFilterChip('Tamamlandı'),
              const SizedBox(width: 8),
              _buildFilterChip('İptal'),
              const SizedBox(width: 8),
              _buildFilterChip('Tarot'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Seans Geçmişi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredSessions.map((session) => _buildSessionCard(session)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = widget.selectedFilter == label;
    return GestureDetector(
      onTap: () => widget.onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
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
            color: isSelected ? AppThemeColors.accentCyan : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
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
            height: 70,
            decoration: BoxDecoration(
              color: session['status'] == 'Tamamlandı'
                  ? Colors.green
                  : Colors.red,
              borderRadius: BorderRadius.circular(2),
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
                    Expanded(
                      child: Text(
                        session['customer'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      session['amount'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session['type'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppThemeColors.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session['date'],
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session['duration'],
                      style: TextStyle(fontSize: 10, color: Colors.white54),
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

class _SavedFiltersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedFilters = [
      {
        'name': 'Aktif Müşteriler (Son 7 Gün)',
        'filters': 'Müşteriler · Aktif · Son 7 gün',
        'count': 24,
      },
      {
        'name': 'Yüksek Değerli Müşteriler',
        'filters': 'Müşteriler · Harcama > ₺500',
        'count': 8,
      },
      {
        'name': 'Tamamlanan Tarot Seansları',
        'filters': 'Seanslar · Tarot · Tamamlandı',
        'count': 156,
      },
      {
        'name': 'Bu Ay Yapılmış Seanslar',
        'filters': 'Seanslar · Eylül 2026',
        'count': 42,
      },
      {
        'name': 'İptal Edilen Seanslar',
        'filters': 'Seanslar · İptal',
        'count': 5,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kaydedilmiş Filtreler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...savedFilters.map((filter) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filter['name'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter['filters'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filter["count"]} sonuç',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppThemeColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: AppThemeColors.accentCyan, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${filter["name"]} filtresi uygulandı'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${filter["name"]} silindi'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
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
                      'Filtre İpucu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Sık kullandığın filtreleri kaydet ve hızlıca uygula',
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
}
