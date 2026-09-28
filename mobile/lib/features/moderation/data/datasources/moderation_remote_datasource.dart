import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/report_target.dart';

class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._dio);

  final Dio _dio;

  /// Backend `validReasons`: harassment, spam, inappropriate_content,
  /// fake_account, scam, other.
  static String backendReason(ReportReason r) => switch (r) {
        ReportReason.spam => 'spam',
        ReportReason.harassment || ReportReason.hate => 'harassment',
        ReportReason.nudity || ReportReason.violence => 'inappropriate_content',
        ReportReason.scam => 'scam',
        ReportReason.impersonation => 'fake_account',
        ReportReason.other => 'other',
      };

  /// Şikayet ayrıntısı: seçilen neden + içerik türü/kimliği + kullanıcı notu.
  static String? buildDetails(
    ReportTarget target,
    ReportReason reason,
    String? details,
  ) {
    final note = details?.trim() ?? '';
    final parts = [
      if (backendReason(reason) != reason.code) reason.label,
      if (target.type != ReportTargetType.user &&
          target.type != ReportTargetType.voiceRoom)
        '${target.typeLabel}: ${target.targetId}',
      if (target.contextLabel?.trim().isNotEmpty == true) target.contextLabel!.trim(),
      if (note.isNotEmpty) note,
    ];
    return parts.isEmpty ? null : parts.join(' — ');
  }

  /// Kullanıcı → `POST /api/user/report`; sesli oda →
  /// `POST /api/chat/rooms/{id}/report` (hedef yoksa oda sahibi); diğer içerik
  /// türleri sahibine kullanıcı şikayeti olarak yazılır.
  Future<void> submit({
    required ReportTarget target,
    required ReportReason reason,
    String? details,
  }) async {
    final body = {
      'reason': backendReason(reason),
      'details': buildDetails(target, reason, details),
    };
    if (target.type == ReportTargetType.voiceRoom) {
      await _dio.safePost<dynamic>(
        ApiEndpoints.chatRoomReport(target.targetId),
        data: {...body, 'targetUserId': ?target.ownerUserId},
      );
      return;
    }
    final userId = target.type == ReportTargetType.user
        ? target.targetId
        : target.ownerUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Bu içeriğin sahibi bulunamadı; şikayet gönderilemedi.');
    }
    await _dio.safePost<dynamic>(
      ApiEndpoints.userReport,
      data: {...body, 'userId': userId.trim()},
    );
  }
}
