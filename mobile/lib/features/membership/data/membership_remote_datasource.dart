import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../wallet/domain/wallet_balances.dart';
import '../domain/membership_package_entity.dart';
import '../domain/membership_purchase_error.dart';
import 'membership_catalog_fallback.dart';
import '../../profile/presentation/premium_2026/profile_membership_helpers.dart';

class MembershipRemoteDataSource {
  MembershipRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MembershipCatalogEntity> loadCatalog(WalletBalances wallet) async {
    for (final path in [
      ApiEndpoints.membershipPackages,
      ApiEndpoints.membershipsCatalog,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final parsed = _parseResponse(res.data, wallet);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return _fallbackCatalog(wallet);
  }

  /// `POST /api/memberships/purchase` — kılavuz §9 `{planId, paymentMethod}`.
  ///
  /// `planId` sunucudaki gerçek plan kimliğidir (tier adı DEĞİL). Sunucu
  /// `jeton` (varsayılan) veya `cfc` ile ödeme alır.
  ///
  /// Yanıt/istek ayrıntıları [MembershipPurchaseException.technicalReport]
  /// içinde taşınır ve loglanır. Sunucunun KESİN cevabı (JSON `error`) geldiğinde
  /// başka gövde/yol denenmez: eskiden 404 `Plan not found` sonrası ~18 tekrar
  /// deneme yapılıp rate-limit (429) gerçek hatayı gizliyordu.
  Future<void> purchaseMembership(
    String planId, {
    String? paymentMethod,
    String planLabel = 'Üyelik',
  }) async {
    final id = planId.trim();
    if (id.isEmpty) {
      throw const ApiException('Plan kimliği boş');
    }
    final method = (paymentMethod?.trim().toLowerCase().isNotEmpty ?? false)
        ? (paymentMethod!.trim().toLowerCase() == 'cfc' ? 'cfc' : 'jeton')
        : 'jeton';
    final body = <String, dynamic>{'planId': id, 'paymentMethod': method};
    final attempts = <MembershipPurchaseAttempt>[];

    for (final path in [
      ApiEndpoints.membershipPurchase,
      '/api/membership/purchase',
    ]) {
      try {
        final res = await _dio.post<dynamic>(path, data: body);
        attempts.add(
          MembershipPurchaseAttempt(
            method: 'POST',
            url: path,
            requestBody: body,
            statusCode: res.statusCode,
            responseBody: res.data,
          ),
        );
        _log('ok', attempts.last);
        return;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        attempts.add(
          MembershipPurchaseAttempt(
            method: 'POST',
            url: path,
            requestBody: body,
            statusCode: status,
            responseBody: data,
            errorType: e.type.name,
          ),
        );
        _log('error', attempts.last);

        // Yol yok (HTML 404 / 405): sıradaki yolu dene.
        if (_isRouteMissing(status, data)) continue;

        final serverMessage = _serverMessage(data) ?? e.message;
        throw MembershipPurchaseException(
          membershipPurchaseUserMessage(
            statusCode: status,
            serverMessage: serverMessage,
            planLabel: planLabel,
          ),
          statusCode: status,
          planId: id,
          attempts: List.unmodifiable(attempts),
          serverMessage: serverMessage,
        );
      }
    }
    throw MembershipPurchaseException(
      'Üyelik satın alma ucu sunucuda bulunamadı. Lütfen uygulamayı güncelleyin '
      'veya destekle iletişime geçin.',
      statusCode: 404,
      planId: id,
      attempts: List.unmodifiable(attempts),
    );
  }

  static bool _isRouteMissing(int? status, Object? data) {
    if (status == 405) return true;
    if (status != 404) return false;
    // Route var ve JSON hata döndüyse (ör. Plan not found) kesin cevaptır.
    if (data is Map &&
        (data['error'] != null || data['message'] != null)) {
      return false;
    }
    return true;
  }

  static String? _serverMessage(Object? data) {
    if (data is Map) {
      final m = data['error'] ?? data['message'];
      final t = m?.toString().trim();
      if (t != null && t.isNotEmpty) return t;
    }
    if (data is String && data.trim().isNotEmpty && !data.contains('<')) {
      return data.trim();
    }
    return null;
  }

  void _log(String phase, MembershipPurchaseAttempt a) {
    // Release'te de logcat'e düşer (debugPrint kısıtlı hızda yazar).
    debugPrint('[Membership] purchase $phase\n${a.summary}');
  }

  MembershipCatalogEntity? _parseResponse(dynamic data, WalletBalances wallet) {
    if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) return null;
      return null;
    }
    if (data is! Map) return null;

    final map = asJsonMap(data);
    final err = map['error'] ?? map['message'];
    if (err != null && err.toString().trim().isNotEmpty) return null;

    if (map['success'] == true && map['data'] is Map) {
      return _parseResponse(map['data'], wallet);
    }

    var catalog = MembershipCatalogEntity.fromJson(map);
    if (catalog.packages.isEmpty) {
      catalog = _fallbackCatalog(wallet);
    }
    // Plans yanıtında mevcut üyelik/gün bilgisi yok; cüzdandan tamamla ki
    // "aktif üyelik" kartı ve uzatma doğru görünsün.
    final currentFromApi = catalog.currentMembership.toLowerCase();
    final walletTier = membershipWireId(wallet.membership);
    final resolvedCurrent = (currentFromApi.isEmpty ||
            currentFromApi == 'basic' ||
            currentFromApi == 'free')
        ? walletTier
        : catalog.currentMembership;
    return catalog.copyWith(
      currentMembership: resolvedCurrent,
      jetonBalance: catalog.jetonBalance > 0 ? catalog.jetonBalance : wallet.jeton,
      cfcBalance: catalog.cfcBalance > 0 ? catalog.cfcBalance : wallet.cfc,
      daysRemaining: catalog.daysRemaining ?? wallet.membershipDaysRemaining,
    );
  }

  MembershipCatalogEntity _fallbackCatalog(WalletBalances wallet) {
    final wire = membershipWireId(wallet.membership);
    return MembershipCatalogEntity(
      packages: fallbackMembershipPackages(
        currentMembership: wire,
        catalogDaysRemaining: wallet.membershipDaysRemaining,
      ),
      currentMembership: wire,
      jetonBalance: wallet.jeton,
      cfcBalance: wallet.cfc,
      daysRemaining: wallet.membershipDaysRemaining,
    );
  }
}
