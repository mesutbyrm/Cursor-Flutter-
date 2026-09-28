import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Rapor türleri.
enum ReportType {
  user, // Kullanıcı raporları
  transaction, // İşlem raporları
  moderation, // Moderation raporları
  broadcast, // Yayın raporları
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
  today, // Bugün
  week, // Son 7 gün
  month, // Son 30 gün
  custom, // Özel
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

/// Rapor üretimi — `GET /api/admin/platform-analytics` (mobil JWT,
/// `analytics.view`). `/api/admin/users/reports/*` backend'de yok.
///
/// Backend sabit pencereler döndürür (bugün / 7 / 30 gün); rapor türü ilgili
/// bölümü seçer.
final adminReportDataProvider = FutureProvider.autoDispose
    .family<ReportData, (ReportType, DateRangeType)>((ref, params) async {
      final dio = ref.watch(dioProvider);
      final (type, dateRange) = params;
      ReportData empty(String title) => ReportData(
        title: title,
        generatedAt: DateTime.now().toIso8601String(),
        type: type,
        dateRange: dateRange,
        rows: const [],
        summary: const {},
      );
      try {
        final res = await dio.safeGet<dynamic>(
          ApiEndpoints.adminPlatformAnalytics,
        );
        final body = res.data;
        final data = body is Map && body['data'] is Map
            ? (body['data'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        Map<String, dynamic> section(String k) => data[k] is Map
            ? (data[k] as Map).cast<String, dynamic>()
            : const {};
        final users = section('users');
        final Map<String, dynamic> picked = switch (type) {
          ReportType.user => {
            'Toplam': users['total'],
            'Günlük aktif': users['dau'],
            'Haftalık aktif': users['wau'],
            'Aylık aktif': users['mau'],
            'Çevrim içi': users['online'],
            'Yeni (bugün)': users['newToday'],
            'Yeni (7 gün)': users['newWeek'],
            'Yeni (30 gün)': users['newMonth'],
            'Tutunma %': users['retentionRate'],
          },
          ReportType.transaction => section('economy'),
          ReportType.moderation => {
            'Yasaklı': users['banned'],
            'Dondurulmuş': users['frozen'],
          },
          ReportType.broadcast => section('platform'),
        };
        final rows = [
          for (final e in picked.entries)
            if (e.value != null) {e.key: e.value},
        ];
        if (rows.isEmpty) return empty('Veri yok');
        final growth = switch (dateRange) {
          DateRangeType.today => users['newToday'],
          DateRangeType.week => users['newWeek'],
          _ => users['newMonth'],
        };
        return ReportData(
          title: '${reportTypeLabel(type)} raporu',
          generatedAt:
              data['generatedAt']?.toString() ??
              DateTime.now().toIso8601String(),
          type: type,
          dateRange: dateRange,
          rows: rows,
          summary: {
            if (type == ReportType.user) 'total': users['total'],
            if (type == ReportType.user && growth != null) 'growth': '+$growth',
          },
        );
      } catch (e) {
        return empty('Hata');
      }
    });

/// Rapor geçmişi — backend'de kayıtlı rapor geçmişi ucu yok.
final adminReportHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) async => const [],
    );

/// Export formatları.
enum ExportFormat { csv, json, pdf }

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
