import '../entities/report_target.dart';

abstract class ModerationRepository {
  Future<void> submitReport({
    required ReportTarget target,
    required ReportReason reason,
    String? details,
  });
}
