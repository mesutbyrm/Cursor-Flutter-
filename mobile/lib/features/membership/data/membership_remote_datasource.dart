import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../wallet/domain/wallet_balances.dart';
import '../domain/membership_package_entity.dart';
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

  /// `POST /api/memberships/purchase` — kılavuz §9 `{planId}`; isteğe bağlı `paymentMethod`.
  Future<void> purchaseMembership(
    String planId, {
    String? paymentMethod,
  }) async {
    final id = planId.trim();
    if (id.isEmpty) {
      throw const ApiException('Plan kimliği boş');
    }
    final method = paymentMethod?.trim();
    await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.membershipPurchase,
      data: {
        'planId': id,
        if (method != null && method.isNotEmpty) 'paymentMethod': method,
      },
    );
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
