import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/report_target.dart';

class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> submit({
    required ReportTarget target,
    required ReportReason reason,
    String? details,
  }) async {
    await _dio.safePost(
      ApiEndpoints.reports,
      data: {
        'targetType': target.apiType,
        'targetId': target.targetId,
        'reason': reason.code,
        'details': details?.trim().isEmpty == true ? null : details?.trim(),
        'type': target.apiType,
        'id': target.targetId,
      },
    );
  }
}
