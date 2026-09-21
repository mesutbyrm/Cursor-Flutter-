import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/discover_background.dart';
import 'package:canlifal_social/core/widgets/discover_tab_layout.dart';

class PsychicEarningsAnalyticsScreen extends ConsumerStatefulWidget {
  const PsychicEarningsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicEarningsAnalyticsScreen> createState() =>
      _PsychicEarningsAnalyticsScreenState();
}

class _PsychicEarningsAnalyticsScreenState
    extends ConsumerState<PsychicEarningsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _selectedEndDate = DateTime(now.year, now.month, now.day);
    _selectedStartDate = _selectedEndDate.subtract(const Duration(days: 30));
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
            'Kazançlar Analizi',
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
              Tab(text: 'Özet'),
              Tab(text: 'Türe Göre'),
              Tab(text: 'Trendi'),
              Tab(text: 'Ödeme'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(),
            _ByTypeTab(),
            _TrendTab(
              startDate: _selectedStartDate,
              endDate: _selectedEndDate,
            ),
            _PaymentTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const totalEarnings = 8750.50;
    const thisMonthEarnings = 2340.75;
    const thisWeekEarnings = 485.25;
    const averagePerSession = 125.50;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        _buildSummaryCard(
          title: 'Toplam Kazanç',
          value: '₺${totalEarnings.toStringAsFixed(2)}',
          icon: Icons.trending_up_rounded,
          color: Colors.green,
          subtitle: 'Tüm zamandan',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                'Bu Ay',
                '₺${thisMonthEarnings.toStringAsFixed(2)}',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                'Bu Hafta',
                '₺${thisWeekEarnings.toStringAsFixed(2)}',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          title: 'Ortalama / Seans',
          value: '₺${averagePerSession.toStringAsFixed(2)}',
          icon: Icons.calculate_rounded,
          color: Colors.orange,
          subtitle: '128 seans',
        ),
        const SizedBox(height: 24),

        // Breakdown
        const Text(
          'Kazanç Dağılımı',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('Tarot Seansları', 4200.00, 48),
          ('Astroloji', 2100.00, 25),
          ('Rehberlik', 1500.00, 20),
          ('Numeroloji', 950.50, 15),
        ].map((item) => _buildBreakdownRow(item.$1, item.$2, item.$3)),
        const SizedBox(height: 24),

        // Top Customers
        const Text(
          'En Karlı Müşteriler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('Ayşe K.', '₺845.00', 6),
          ('Zeynep M.', '₺720.50', 5),
          ('Fatma D.', '₺625.00', 4),
        ].map(
          (item) => _buildTopCustomerRow(item.$1, item.$2, item.$3),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String type, double amount, int count) {
    final percentage = (amount / 8750.50 * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                type,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '₺${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count seans',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomerRow(String name, String amount, int sessions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://api.dicebear.com/7.x/avataaars/svg?seed=$name',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$sessions seans',
                  style:
                      TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ByTypeTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Hizmet Türlerine Göre Kazançlar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...[
          {
            'type': 'Tarot Seansları',
            'earnings': 4200.00,
            'sessions': 48,
            'avgTime': '22',
            'rating': 4.8,
          },
          {
            'type': 'Astroloji Danışmanlığı',
            'earnings': 2100.00,
            'sessions': 25,
            'avgTime': '28',
            'rating': 4.6,
          },
          {
            'type': 'Yaşamsal Rehberlik',
            'earnings': 1500.00,
            'sessions': 20,
            'avgTime': '35',
            'rating': 4.9,
          },
          {
            'type': 'Numeroloji Analizi',
            'earnings': 950.50,
            'sessions': 15,
            'avgTime': '18',
            'rating': 4.5,
          },
        ].map((service) => _buildServiceCard(service)),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service['type'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₺${(service['earnings'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoBubble('${service['sessions']} Seans', Icons.event),
              _buildInfoBubble('${service['avgTime']} dk Ort.', Icons.timer),
              _buildInfoBubble('${service['rating']} ⭐', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBubble(String text, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

class _TrendTab extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _TrendTab({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Haftalık Kazanç Trendi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Chart-like bars
        ...[
          ('1 Hafta', 485.25, 0.55),
          ('2 Hafta', 715.50, 0.82),
          ('3 Hafta', 825.00, 0.94),
          ('4 Hafta', 315.00, 0.36),
        ].map((week) => _buildWeekBar(week.$1, week.$2, week.$3)),

        const SizedBox(height: 24),
        const Text(
          'Günlük Ortalamalar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildTrendRow('En Yüksek Gün', '₺385.50', '12 Şub'),
              const SizedBox(height: 10),
              _buildTrendRow('En Düşük Gün', '₺45.00', '3 Şub'),
              const SizedBox(height: 10),
              _buildTrendRow('Ort. Günlük', '₺78.01', 'Son 30 gün'),
            ],
          ),
        ),

        const SizedBox(height: 24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trend Analizi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Son 30 güne kıyasla +18.5% artış',
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

  Widget _buildWeekBar(String label, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '₺${amount.toStringAsFixed(2)}',
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
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(
                  AppThemeColors.accentCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String label, String value, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            Text(
              date,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PaymentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ödeme Geçmişi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bakiye',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      '₺2,150.75',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Çekme isteği hazırlanıyor...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Çek',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...[
          {
            'date': '15 Şubat 2024',
            'amount': 1500.00,
            'status': 'Tamamlandı',
            'method': 'Banka Transferi',
          },
          {
            'date': '31 Ocak 2024',
            'amount': 2200.50,
            'status': 'Tamamlandı',
            'method': 'Banka Transferi',
          },
          {
            'date': '15 Ocak 2024',
            'amount': 1800.00,
            'status': 'Tamamlandı',
            'method': 'Banka Transferi',
          },
        ].map((payment) => _buildPaymentCard(payment)),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment['date'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                payment['method'],
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  payment['status'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '₺${(payment['amount'] as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
