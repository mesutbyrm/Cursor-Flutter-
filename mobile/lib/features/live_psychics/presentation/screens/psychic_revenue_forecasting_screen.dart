import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicRevenueForcastingScreen extends ConsumerStatefulWidget {
  const PsychicRevenueForcastingScreen({super.key});

  @override
  ConsumerState<PsychicRevenueForcastingScreen> createState() =>
      _PsychicRevenueForcastingScreenState();
}

class _PsychicRevenueForcastingScreenState
    extends ConsumerState<PsychicRevenueForcastingScreen>
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
                    'Gelir Tahminlemesi',
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
                      Tab(text: 'Tahminler'),
                      Tab(text: 'Trend'),
                      Tab(text: 'Hedefler'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ForecastsTab(),
                      _TrendAnalysisTab(),
                      _GoalsManagementTab(),
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

class _ForecastsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final forecasts = [
      {'period': 'Sonraki 30 Gün', 'amount': '₺2,500', 'variance': '±₺300', 'confidence': 94},
      {'period': 'Sonraki 90 Gün', 'amount': '₺7,200', 'variance': '±₺800', 'confidence': 87},
      {'period': 'Sonraki 180 Gün', 'amount': '₺15,000', 'variance': '±₺2,000', 'confidence': 78},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...forecasts.map((f) {
            final confidence = f['confidence'] as int;
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
                        Text(
                          f['period'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Chip(
                          label: Text('${confidence}% Güven'),
                          backgroundColor: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          f['amount'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4FC3F7),
                          ),
                        ),
                        Text(
                          f['variance'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidence / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppThemeColors.accentCyan,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Tahminin Temeli',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
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
                _buildBasisRow('Ortalama Seans Geliri', '₺85'),
                const SizedBox(height: 10),
                _buildBasisRow('Aylık Beklenen Seans', '120'),
                const SizedBox(height: 10),
                _buildBasisRow('Sezonsal Ayarlama', '+12% (Yaz)'),
                const SizedBox(height: 10),
                _buildBasisRow('Büyüm Trendi', '+8.5% aylık'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasisRow(String label, String value) {
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

class _TrendAnalysisTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final monthlyData = [
      {'month': 'Eyl', 'revenue': 1840, 'avg': 1650},
      {'month': 'Ekim', 'revenue': 1980, 'avg': 1700},
      {'month': 'Kas', 'revenue': 2100, 'avg': 1750},
      {'month': 'Ara', 'revenue': 2350, 'avg': 1850},
      {'month': 'Oca', 'revenue': 1650, 'avg': 1750},
      {'month': 'Şub', 'revenue': 1820, 'avg': 1800},
      {'month': 'Mar', 'revenue': 2050, 'avg': 1850},
      {'month': 'Nis', 'revenue': 2200, 'avg': 1900},
      {'month': 'May', 'revenue': 2400, 'avg': 2000},
      {'month': 'Haz', 'revenue': 2650, 'avg': 2100},
      {'month': 'Tem', 'revenue': 2780, 'avg': 2150},
      {'month': 'Ağu', 'revenue': 2920, 'avg': 2200},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '12 Aylık Gelir Trendi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _TrendChartPainter(monthlyData),
                    size: Size(double.infinity, 200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sezonsal Kalıplar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            {'season': 'Yaz (Haz-Ağu)', 'change': '+15%', 'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFFCA28)},
            {'season': 'Sonbahar (Eyl-Kas)', 'change': '+8%', 'icon': Icons.nature_rounded, 'color': Color(0xFFFFA726)},
            {'season': 'Kış (Ara-Şub)', 'change': '-5%', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFF29B6F6)},
            {'season': 'İlkbahar (Mar-May)', 'change': '+12%', 'icon': Icons.local_florist_rounded, 'color': Color(0xFF66BB6A)},
          ].map((s) {
            final isNegative = (s['change'] as String).contains('-');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (s['color'] as Color).withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['season'] as String,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    s['change'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isNegative ? Color(0xFFEF5350) : Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Bazı İstatistikler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                    ),
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Büyüme Hızı',
                        style: TextStyle(fontSize: 12, color: Color(0xFF80DEEA)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '+8.5% aylık',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.3),
                    ),
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volatilite',
                        style: TextStyle(fontSize: 12, color: Color(0xFFCE93D8)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '±₺185',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _TrendChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final avgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    final width = size.width;
    final height = size.height;
    final maxValue = 3000.0;
    final padding = 30.0;

    // Grid
    for (int i = 0; i <= 3; i++) {
      final y = padding + (height - padding * 2) * (i / 3);
      canvas.drawLine(
        Offset(padding, y),
        Offset(width, y),
        gridPaint,
      );
    }

    // Data points
    final pointsRevenue = <Offset>[];
    final pointsAvg = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = padding + (width - padding * 2) * (i / (data.length - 1));
      final yRevenue =
          height - padding - ((data[i]['revenue'] as int) / maxValue) * (height - padding * 2);
      final yAvg = height - padding - ((data[i]['avg'] as int) / maxValue) * (height - padding * 2);

      pointsRevenue.add(Offset(x, yRevenue));
      pointsAvg.add(Offset(x, yAvg));
    }

    // Draw average line
    for (int i = 0; i < pointsAvg.length - 1; i++) {
      canvas.drawLine(pointsAvg[i], pointsAvg[i + 1], avgPaint);
    }

    // Draw revenue line
    for (int i = 0; i < pointsRevenue.length - 1; i++) {
      canvas.drawLine(pointsRevenue[i], pointsRevenue[i + 1], paint);
    }

    // Draw points
    for (final point in pointsRevenue) {
      canvas.drawCircle(point, 4, paint);
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) => false;
}

class _GoalsManagementTab extends StatefulWidget {
  @override
  State<_GoalsManagementTab> createState() => _GoalsManagementTabState();
}

class _GoalsManagementTabState extends State<_GoalsManagementTab> {
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = [
      {'period': 'Eylül Hedefi', 'target': '₺2,800', 'current': '₺2,500', 'progress': 89},
      {'period': '2026 Q4 Hedefi', 'target': '₺8,000', 'current': '₺7,200', 'progress': 90},
      {'period': '2027 Hedefi', 'target': '₺48,000', 'current': '₺24,500', 'progress': 51},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gelir Hedefleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...goals.map((g) {
            final progress = g['progress'] as int;
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
                        Text(
                          g['period'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$progress% İlerleme',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          g['current'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4FC3F7),
                          ),
                        ),
                        Text(
                          '/ ${g['target']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 100 ? const Color(0xFF66BB6A) : const Color(0xFF4FC3F7),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Yeni Hedef Ekle',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Örn: Ekim Hedefi — ₺3,000',
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
                borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hedef eklendi'),
                    duration: Duration(seconds: 2),
                  ),
                );
                _goalController.clear();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Hedef Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Öneriler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF66BB6A).withValues(alpha: 0.3),
              ),
              color: Color(0xFF66BB6A).withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Color(0xFF66BB6A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tarafından Önerilen',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66BB6A), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mevcut büyüm oranınız (8.5%/ay) ile hedefleriniz 2026 sonuna kadar %97 oranında başarılı olacak. Ses kalitesi ve müşteri memnuniyeti arttırılırsa bu başarı %105+ olabilir.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
