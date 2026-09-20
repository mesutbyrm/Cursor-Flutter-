import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_advanced_reporting_providers.dart';
import '../providers/staff_access_provider.dart';

/// Gelişmiş raporlama — detaylı istatistikler ve export.
class AdminAdvancedReportingPage extends ConsumerStatefulWidget {
  const AdminAdvancedReportingPage({super.key});

  @override
  ConsumerState<AdminAdvancedReportingPage> createState() =>
      _AdminAdvancedReportingPageState();
}

class _AdminAdvancedReportingPageState
    extends ConsumerState<AdminAdvancedReportingPage> {
  ReportType _selectedType = ReportType.user;
  DateRangeType _selectedDateRange = DateRangeType.week;

  void _generateReport() {
    ref.refresh(adminReportDataProvider((_selectedType, _selectedDateRange)));
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Raporlama yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final reportAsync =
        ref.watch(adminReportDataProvider((_selectedType, _selectedDateRange)));
    final historyAsync = ref.watch(adminReportHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DiscoverTabHeader(
                      title: 'Gelişmiş Raporlama',
                      subtitle: 'Detaylı istatistikler',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _generateReport,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async => _generateReport(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Rapor Türü Seçimi
                    _SectionTitle('Rapor Türü'),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final type in ReportType.values)
                            _ReportTypeCard(
                              type: type,
                              isSelected: _selectedType == type,
                              onTap: () {
                                setState(() => _selectedType = type);
                                _generateReport();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarih Aralığı Seçimi
                    _SectionTitle('Tarih Aralığı'),
                    _DateRangeSelector(
                      selectedRange: _selectedDateRange,
                      onRangeChanged: (range) {
                        setState(() => _selectedDateRange = range);
                        _generateReport();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Rapor Görünümü
                    _SectionTitle('Rapor'),
                    reportAsync.when(
                      data: (report) => Column(
                        children: [
                          _ReportViewer(report: report),
                          const SizedBox(height: 24),
                          _ExportButtons(report: report),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),

                    // Rapor Geçmişi
                    _SectionTitle('Rapor Geçmişi'),
                    historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) {
                          return Center(
                            child: DiscoverEmptyState(
                              icon: Icons.history_rounded,
                              message: 'Rapor geçmişi yok',
                            ),
                          );
                        }
                        return Column(
                          children: history.map((item) {
                            return _ReportHistoryCard(item: item);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (type) {
      case ReportType.user:
        return Icons.people_rounded;
      case ReportType.transaction:
        return Icons.swap_horiz_rounded;
      case ReportType.moderation:
        return Icons.flag_rounded;
      case ReportType.broadcast:
        return Icons.live_tv_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accentPink.withValues(alpha: 0.2)
              : context.colors.surfaceContainer,
          border: Border.all(
            color: isSelected
                ? AppThemeColors.accentPink
                : AppThemeColors.accentPink.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              color: isSelected
                  ? AppThemeColors.accentPink
                  : context.colors.onSurfaceMuted,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              reportTypeLabel(type),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11,
                color: isSelected
                    ? AppThemeColors.accentPink
                    : context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final DateRangeType selectedRange;
  final Function(DateRangeType) onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2,
      children: [
        for (final range in DateRangeType.values)
          _DateRangeButton(
            range: range,
            isSelected: selectedRange == range,
            onTap: () => onRangeChanged(range),
          ),
      ],
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  final DateRangeType range;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accentCyan.withValues(alpha: 0.2)
              : context.colors.surfaceContainer,
          border: Border.all(
            color: isSelected
                ? AppThemeColors.accentCyan
                : AppThemeColors.accentCyan.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            dateRangeLabel(range),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
              color: isSelected
                  ? AppThemeColors.accentCyan
                  : context.colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportViewer extends StatelessWidget {
  const _ReportViewer({required this.report});

  final ReportData report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oluşturuldu: ${report.generatedAt}',
            style: TextStyle(
              fontSize: 10,
              color: context.colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (report.summary.isNotEmpty)
            Column(
              children: [
                _SummaryRow('Toplam', report.summary['total']?.toString() ?? '0'),
                _SummaryRow('Ortalama', report.summary['average']?.toString() ?? '0'),
                if (report.summary['growth'] != null)
                  _SummaryRow('Artış', report.summary['growth']?.toString() ?? '0%'),
                const SizedBox(height: 12),
              ],
            ),
          if (report.rows.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.rows.length} satır',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ...report.rows.take(5).map((row) {
                  final key = row.keys.first;
                  final value = row[key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '$key: $value',
                      style: TextStyle(fontSize: 10, color: context.colors.onSurface),
                    ),
                  );
                }),
                if (report.rows.length > 5)
                  Text(
                    '+${report.rows.length - 5} daha',
                    style: TextStyle(
                      fontSize: 9,
                      color: context.colors.onSurfaceMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.onSurfaceMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppThemeColors.accentCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  const _ExportButtons({required this.report});

  final ReportData report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dışa Aktar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final format in ExportFormat.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ExportButton(
                    format: format,
                    onTap: () {},
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.format,
    required this.onTap,
  });

  final ExportFormat format;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (format) {
      case ExportFormat.csv:
        return Icons.table_chart_rounded;
      case ExportFormat.json:
        return Icons.code_rounded;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          border: Border.all(
            color: AppThemeColors.accentPink.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              color: AppThemeColors.accentPink,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              exportFormatLabel(format),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: AppThemeColors.accentPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final reportType = item['type'] as String?;
    final dateRange = item['date_range'] as String?;
    final generatedAt = item['generated_at'] as String?;
    final rowCount = item['row_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
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
                      reportType ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      dateRange ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  '$rowCount satır',
                  style: const TextStyle(fontSize: 9),
                ),
                backgroundColor: AppThemeColors.accentCyan.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Oluşturuldu: $generatedAt',
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
