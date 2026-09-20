import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Rapor türleri.
enum ReportType {
  user,         // Kullanıcı raporları
  transaction,  // İşlem raporları
  moderation,   // Moderation raporları
  broadcast,    // Yayın raporları
}

String reportTypeLabel(ReportType type) {
  switch (type) {
    case ReportType.user:
      return 'Kullanıcı';
    case ReportType.transaction:
      return 'İşlem';
    case ReportType.moderation:
      return 'Moderation';
    case ReportType.broadcast:
      return 'Yayın';
  }
}

/// Tarih aralığı.
enum DateRangeType {
  today,     // Bugün
  week,      // Son 7 gün
  month,     // Son 30 gün
  custom,    // Özel
}

String dateRangeLabel(DateRangeType type) {
  switch (type) {
    case DateRangeType.today:
      return 'Bugün';
    case DateRangeType.week:
      return 'Son 7 Gün';
    case DateRangeType.month:
      return 'Son 30 Gün';
    case DateRangeType.custom:
      return 'Özel';
  }
}

/// Rapor verisi.
class ReportData {
  final String title;
  final String generatedAt;
  final ReportType type;
  final DateRangeType dateRange;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;

  const ReportData({
    required this.title,
    required this.generatedAt,
    required this.type,
    required this.dateRange,
    required this.rows,
    required this.summary,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      title: json['title'] as String? ?? 'Rapor',
      generatedAt: json['generated_at'] as String? ?? '',
      type: _parseReportType(json['type']),
      dateRange: _parseDateRange(json['date_range']),
      rows: List<Map<String, dynamic>>.from(
        (json['rows'] as List? ?? []).map((e) => e is Map ? e : {}),
      ),
      summary: (json['summary'] as Map? ?? {}).cast<String, dynamic>(),
    );
  }

  static ReportType _parseReportType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'user':
          return ReportType.user;
        case 'transaction':
          return ReportType.transaction;
        case 'moderation':
          return ReportType.moderation;
        case 'broadcast':
          return ReportType.broadcast;
      }
    }
    return ReportType.user;
  }

  static DateRangeType _parseDateRange(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'today':
          return DateRangeType.today;
        case 'week':
          return DateRangeType.week;
        case 'month':
          return DateRangeType.month;
        case 'custom':
          return DateRangeType.custom;
      }
    }
    return DateRangeType.week;
  }
}

/// Rapor üretimi.
final adminReportDataProvider =
    FutureProvider.autoDispose.family<ReportData, (ReportType, DateRangeType)>(
        (ref, params) async {
  final dio = ref.watch(dioProvider);
  final (type, dateRange) = params;
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/reports/generate',
      query: {
        'type': type.name,
        'date_range': dateRange.name,
      },
    );
    if (res.data is Map) {
      return ReportData.fromJson(res.data as Map<String, dynamic>);
    }
    return ReportData(
      title: 'Hata',
      generatedAt: DateTime.now().toIso8601String(),
      type: type,
      dateRange: dateRange,
      rows: [],
      summary: {},
    );
  } catch (e) {
    return ReportData(
      title: 'Hata',
      generatedAt: DateTime.now().toIso8601String(),
      type: type,
      dateRange: dateRange,
      rows: [],
      summary: {},
    );
  }
});

/// Rapor geçmişi.
final adminReportHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/reports/history',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Export formatları.
enum ExportFormat {
  csv,
  json,
  pdf,
}

String exportFormatLabel(ExportFormat format) {
  switch (format) {
    case ExportFormat.csv:
      return 'CSV';
    case ExportFormat.json:
      return 'JSON';
    case ExportFormat.pdf:
      return 'PDF';
  }
}

/// Rapor sayısı.
final adminReportCountProvider = Provider<int>((ref) {
  final history = ref.watch(adminReportHistoryProvider).valueOrNull ?? [];
  return history.length;
});
