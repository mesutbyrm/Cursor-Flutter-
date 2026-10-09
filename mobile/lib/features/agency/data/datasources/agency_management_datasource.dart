import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/agency_management_models.dart';
import 'agency_wallet_datasource.dart' show serverErrorMessage;

/// Ajans yönetimi uçları (keşif, başvuru, performans, vaat, hedef, hak ediş,
/// duyuru, çalışan yetkisi, yayıncı paneli). Hatalar sunucunun Türkçe mesajıyla
/// [ApiException] olarak fırlatılır.
class AgencyManagementDataSource {
  AgencyManagementDataSource(this._dio);

  final Dio _dio;

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final body = asJsonMap(res.data);
      return body.containsKey('data') ? body['data'] : body;
    } catch (e) {
      throw ApiException(serverErrorMessage(e, fallback: 'Veriler yüklenemedi'));
    }
  }

  /// Başarı mesajını döner.
  Future<String> _send(String method, String path, {Object? data, Map<String, dynamic>? query, String ok = 'İşlem tamamlandı'}) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      final body = asJsonMap(res.data);
      final msg = body['message'];
      return msg is String && msg.isNotEmpty ? msg : ok;
    } catch (e) {
      throw ApiException(serverErrorMessage(e));
    }
  }

  // ── Keşif ───────────────────────────────────────────────
  Future<List<AgencyCard>> agencies({String? sort, String? q}) async {
    final data = asJsonMap(await _get(ApiEndpoints.agencies, {
      if (sort != null) 'sort': sort,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'limit': 50,
    }));
    return asJsonList(data['agencies']).map(AgencyCard.fromJson).toList();
  }

  Future<AgencyDetail> agencyDetail(String id) async => AgencyDetail.fromJson(await _get(ApiEndpoints.agencyDetail(id)));

  Future<String> applyToAgency(String id, {String? message}) => _send(
        'POST',
        ApiEndpoints.agencyJoinRequest(id),
        data: {if (message != null && message.trim().isNotEmpty) 'message': message.trim()},
        ok: 'Başvurunuz iletildi',
      );

  Future<String> withdrawApplication(String id) =>
      _send('DELETE', ApiEndpoints.agencyJoinRequest(id), ok: 'Başvuru geri çekildi');

  // ── Ajans paneli ────────────────────────────────────────
  Future<List<JoinRequestView>> joinRequests({String status = 'pending'}) async =>
      asJsonList(await _get(ApiEndpoints.agencyJoinRequests, {'status': status})).map(JoinRequestView.fromJson).toList();

  Future<String> reviewJoinRequest(String id, {required bool accept, String? note}) => _send(
        'POST',
        ApiEndpoints.agencyJoinRequests,
        data: {'requestId': id, 'action': accept ? 'accept' : 'reject', if (note != null && note.isNotEmpty) 'note': note},
      );

  Future<AgencyPerformanceReport> performance({String period = 'weekly', bool includeFormer = false}) async =>
      AgencyPerformanceReport.fromJson(
        await _get(ApiEndpoints.agencyPerformance, {'period': period, if (includeFormer) 'former': '1'}),
      );

  Future<MemberPerformanceDetail> memberPerformance(String userId, {String period = 'weekly'}) async =>
      MemberPerformanceDetail.fromJson(await _get(ApiEndpoints.agencyMemberPerformance(userId), {'period': period}));

  Future<String> setTarget({
    required String userId,
    required String period,
    required int targetMinutes,
    int? minDays,
    int bonusJeton = 0,
  }) =>
      _send('POST', ApiEndpoints.agencyTargets, data: {
        'userId': userId,
        'period': period,
        'targetMinutes': targetMinutes,
        if (minDays != null && minDays > 0) 'minDays': minDays,
        'bonusJeton': bonusJeton,
      });

  Future<String> closeTarget(String targetId) => _send('DELETE', ApiEndpoints.agencyTargets, query: {'id': targetId});

  Future<List<AccrualView>> accruals({String? status}) async =>
      asJsonList(await _get(ApiEndpoints.agencyAccruals, {if (status != null) 'status': status})).map(AccrualView.fromJson).toList();

  Future<String> closePeriod(String period) => _send('POST', ApiEndpoints.agencyAccruals, data: {'action': 'close', 'period': period});

  Future<String> payAccrual(String id) => _send('POST', ApiEndpoints.agencyAccruals, data: {'action': 'pay', 'accrualId': id});

  Future<String> voidAccrual(String id, String reason) =>
      _send('POST', ApiEndpoints.agencyAccruals, data: {'action': 'void', 'accrualId': id, 'reason': reason});

  Future<(List<AgencyAnnouncement>, bool)> announcements() async {
    try {
      final res = await _dio.get<dynamic>(ApiEndpoints.agencyAnnouncements);
      final body = asJsonMap(res.data);
      return (asJsonList(body['data']).map(AgencyAnnouncement.fromJson).toList(), body['canPost'] == true);
    } catch (e) {
      throw ApiException(serverErrorMessage(e, fallback: 'Duyurular yüklenemedi'));
    }
  }

  Future<String> postAnnouncement({required String title, required String body, bool pinned = false}) =>
      _send('POST', ApiEndpoints.agencyAnnouncements, data: {'title': title, 'body': body, 'pinned': pinned});

  Future<String> deleteAnnouncement(String id) => _send('DELETE', ApiEndpoints.agencyAnnouncements, query: {'id': id});

  Future<List<StaffEntry>> staff() async =>
      asJsonList(asJsonMap(await _get(ApiEndpoints.agencyStaff))['staff']).map(StaffEntry.fromJson).toList();

  Future<String> setStaff(String userId, List<String> permissions) =>
      _send('PUT', ApiEndpoints.agencyStaff, data: {'userId': userId, 'permissions': permissions});

  Future<String> removeStaff(String userId) => _send('DELETE', ApiEndpoints.agencyStaff, query: {'userId': userId});

  Future<AgencyPromisesData> promises() async => AgencyPromisesData.fromJson(await _get(ApiEndpoints.agencyPromises));

  Future<String> createPromise(Map<String, dynamic> fields) =>
      _send('POST', ApiEndpoints.agencyPromises, data: {'action': 'create', ...fields});

  Future<String> newPromiseVersion(String promiseId, Map<String, dynamic> fields) =>
      _send('POST', ApiEndpoints.agencyPromises, data: {'action': 'new_version', 'promiseId': promiseId, ...fields});

  Future<String> withdrawPromiseVersion(String versionId) =>
      _send('POST', ApiEndpoints.agencyPromises, data: {'action': 'withdraw', 'versionId': versionId});

  Future<String> archivePromise(String promiseId) =>
      _send('POST', ApiEndpoints.agencyPromises, data: {'action': 'archive', 'promiseId': promiseId});

  // ── Yayıncı ─────────────────────────────────────────────
  Future<BroadcasterPanel> broadcasterPanel() async => BroadcasterPanel.fromJson(await _get(ApiEndpoints.agencyBroadcaster));

  Future<String> acceptPromise(String versionId) =>
      _send('POST', ApiEndpoints.agencyPromiseAccept(versionId), data: {'confirm': true});

  Future<String> requestLeave({String? reason}) => _send(
        'POST',
        ApiEndpoints.agencyLeave,
        data: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
        ok: 'Ayrılma talebiniz gönderildi',
      );

  Future<String> cancelLeave() => _send('DELETE', ApiEndpoints.agencyLeave, ok: 'Ayrılma talebi iptal edildi');
}
