import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../wallet/domain/wallet_balances.dart';
import '../domain/membership_package_entity.dart';
import 'membership_catalog_fallback.dart';

class MembershipRemoteDataSource {
  MembershipRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MembershipCatalogEntity> loadCatalog(WalletBalances wallet) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.membershipPackages);
      final parsed = _parseResponse(res.data, wallet);
      if (parsed != null) return parsed;
    } catch (_) {
      // 404 HTML, oturum, ağ
    }
    return _fallbackCatalog(wallet);
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
    return catalog.copyWith(
      jetonBalance: catalog.jetonBalance > 0 ? catalog.jetonBalance : wallet.jeton,
      cfcBalance: catalog.cfcBalance > 0 ? catalog.cfcBalance : wallet.cfc,
      daysRemaining: catalog.daysRemaining ?? wallet.membershipDaysRemaining,
    );
  }

  MembershipCatalogEntity _fallbackCatalog(WalletBalances wallet) {
    return MembershipCatalogEntity(
      packages: fallbackMembershipPackages(
        currentMembership: wallet.membership ?? 'basic',
        catalogDaysRemaining: wallet.membershipDaysRemaining,
      ),
      currentMembership: wallet.membership ?? 'basic',
      jetonBalance: wallet.jeton,
      cfcBalance: wallet.cfc,
      daysRemaining: wallet.membershipDaysRemaining,
    );
  }
}
