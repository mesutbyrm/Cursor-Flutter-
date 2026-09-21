import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/discover_background.dart';

class PsychicAnalyticsExportScreen extends ConsumerStatefulWidget {
  const PsychicAnalyticsExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicAnalyticsExportScreen> createState() =>
      _PsychicAnalyticsExportScreenState();
}

class _PsychicAnalyticsExportScreenState
    extends ConsumerState<PsychicAnalyticsExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFormat = 'PDF';
  String _selectedReportType = 'Özet';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

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
            'Analitik Dışa Aktarma',
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
              Tab(text: 'İhraç Et'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ExportTab(
              selectedFormat: _selectedFormat,
              selectedReportType: _selectedReportType,
              startDate: _startDate,
              endDate: _endDate,
              onFormatChanged: (format) =>
                  setState(() => _selectedFormat = format),
              onReportTypeChanged: (type) =>
                  setState(() => _selectedReportType = type),
              onStartDateChanged: (date) =>
                  setState(() => _startDate = date),
              onEndDateChanged: (date) =>
                  setState(() => _endDate = date),
            ),
            _ExportHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ExportTab extends StatefulWidget {
  final String selectedFormat;
  final String selectedReportType;
  final DateTime startDate;
  final DateTime endDate;
  final Function(String) onFormatChanged;
  final Function(String) onReportTypeChanged;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;

  const _ExportTab({
    required this.selectedFormat,
    required this.selectedReportType,
    required this.startDate,
    required this.endDate,
    required this.onFormatChanged,
    required this.onReportTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  bool _isExporting = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? widget.startDate : widget.endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppThemeColors.accentCyan,
              onPrimary: Colors.black,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        widget.onStartDateChanged(picked);
      } else {
        widget.onEndDateChanged(picked);
      }
    }
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.selectedReportType} raporu ${widget.selectedFormat} olarak indirildi',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rapor Türü',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildReportTypeSelector(),
        const SizedBox(height: 24),
        const Text(
          'Dışa Aktarma Formatı',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildFormatSelector(),
        const SizedBox(height: 24),
        const Text(
          'Tarih Aralığı',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Başlangıç Tarihi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: AppThemeColors.accentCyan),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bitiş Tarihi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: AppThemeColors.accentCyan),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.endDate.day}/${widget.endDate.month}/${widget.endDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
                      'Rapor Bilgisi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.selectedReportType} raporu şunları içerir: detaylı veriler, grafikler ve özetler',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _performExport,
          icon: _isExporting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: Text(
            _isExporting ? 'İndiriliyor...' : 'İndir',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeColors.accentCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            disabledBackgroundColor:
                AppThemeColors.accentCyan.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            widget.onStartDateChanged(DateTime.now().subtract(const Duration(days: 30)));
            widget.onEndDateChanged(DateTime.now());
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Sıfırla'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    final reportTypes = [
      {'name': 'Özet', 'icon': Icons.summarize_rounded, 'desc': 'Genel özet'},
      {
        'name': 'Kazançlar',
        'icon': Icons.trending_up_rounded,
        'desc': 'Gelir raporu'
      },
      {
        'name': 'Müşteriler',
        'icon': Icons.people_rounded,
        'desc': 'Müşteri analizi'
      },
      {'name': 'Seanslar', 'icon': Icons.history_rounded, 'desc': 'Seans detayları'},
      {
        'name': 'Puanlamalar',
        'icon': Icons.star_rate_rounded,
        'desc': 'Rating analizi'
      },
    ];

    return Column(
      children: reportTypes.map((type) {
        final isSelected = widget.selectedReportType == type['name'];
        return GestureDetector(
          onTap: () => widget.onReportTypeChanged(type['name'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppThemeColors.accentCyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppThemeColors.accentCyan
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(type['icon'] as IconData,
                    color: isSelected
                        ? AppThemeColors.accentCyan
                        : Colors.white70,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppThemeColors.accentCyan : Colors.white,
                        ),
                      ),
                      Text(
                        type['desc'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppThemeColors.accentCyan, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [
      {'name': 'PDF', 'icon': Icons.description_rounded},
      {'name': 'Excel', 'icon': Icons.table_chart_rounded},
      {'name': 'CSV', 'icon': Icons.text_fields_rounded},
    ];

    return Row(
      children: formats.map((format) {
        final isSelected = widget.selectedFormat == format['name'];
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                widget.onFormatChanged(format['name'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppThemeColors.accentCyan
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(format['icon'] as IconData,
                      color: isSelected
                          ? AppThemeColors.accentCyan
                          : Colors.white54,
                      size: 24),
                  const SizedBox(height: 8),
                  Text(
                    format['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppThemeColors.accentCyan
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList()
          .expand((widget) => [widget, const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
}

class _ExportHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportHistory = [
      {
        'type': 'Özet Raporu',
        'format': 'PDF',
        'date': '2026-09-20',
        'time': '14:32',
        'size': '2.4 MB',
        'status': 'Tamamlandı',
      },
      {
        'type': 'Kazanç Analizi',
        'format': 'Excel',
        'date': '2026-09-18',
        'time': '10:15',
        'size': '1.8 MB',
        'status': 'Tamamlandı',
      },
      {
        'type': 'Müşteri Raporu',
        'format': 'CSV',
        'date': '2026-09-15',
        'time': '16:45',
        'size': '856 KB',
        'status': 'Tamamlandı',
      },
      {
        'type': 'Seans Detayları',
        'format': 'PDF',
        'date': '2026-09-12',
        'time': '09:20',
        'size': '3.2 MB',
        'status': 'Tamamlandı',
      },
      {
        'type': 'Rating Analizi',
        'format': 'Excel',
        'date': '2026-09-10',
        'time': '13:00',
        'size': '1.1 MB',
        'status': 'Tamamlandı',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'İndirme Geçmişi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...exportHistory.map((item) => Container(
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
                        Text(
                          item['type'],
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
                                color: _getFormatColor(item['format'])
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['format'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getFormatColor(item['format']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item["date"]} ${item["time"]}',
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
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        color: AppThemeColors.accentCyan, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item["type"]} yeniden indirildi'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Boyut: ${item["size"]}',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['status'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.storage_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Depolama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Toplam: 12.3 MB / 1 GB (Kullanılan: %1.2)',
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

  Color _getFormatColor(String format) {
    switch (format) {
      case 'PDF':
        return Colors.red;
      case 'Excel':
        return Colors.green;
      case 'CSV':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }
}
