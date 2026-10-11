import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_finance_summary.dart';
import 'admin_panel_providers.dart';

final adminFinanceSummaryProvider =
    FutureProvider.autoDispose.family<AdminFinanceSummary, String>((ref, period) {
  return ref.read(adminRemoteProvider).fetchFinanceSummary(period: period);
});
