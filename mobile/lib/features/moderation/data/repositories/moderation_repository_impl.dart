import '../../domain/entities/report_target.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_datasource.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  ModerationRepositoryImpl(this._remote);

  final ModerationRemoteDataSource _remote;

  @override
  Future<void> submitReport({
    required ReportTarget target,
    required ReportReason reason,
    String? details,
  }) =>
      _remote.submit(
        target: target,
        reason: reason,
        details: details,
      );
}
