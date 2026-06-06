import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/report_target.dart';

/// Rapor ekranına git (`/report` + [ReportTarget] extra).
void openReportFlow(BuildContext context, ReportTarget target) {
  context.push('/report', extra: target);
}
