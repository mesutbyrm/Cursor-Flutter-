import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

class AgencyWalletSnapshot {
  const AgencyWalletSnapshot({
    this.jetonBalance = 0,
    this.totalBonus = 0,
    this.isLocked = false,
    this.transactions = const [],
  });

  final double jetonBalance;
  final double totalBonus;
  final bool isLocked;
  final List<Map<String, dynamic>> transactions;

  static AgencyWalletSnapshot fromJson(Map<String, dynamic> map) {
    final wallet = map['wallet'] is Map
        ? asJsonMap(map['wallet'])
        : map;
    return AgencyWalletSnapshot(
      jetonBalance: asDouble(
            pick(wallet, ['jetonBalance', 'balance', 'available']),
          ) ??
          0,
      totalBonus: asDouble(pick(wallet, ['totalBonus', 'bonus'])) ?? 0,
      isLocked: pick(wallet, ['isLocked', 'locked']) == true,
      transactions: _txnList(map['transactions'] ?? wallet['transactions']),
    );
  }

  static List<Map<String, dynamic>> _txnList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => asJsonMap(e)).toList();
  }
}

double? asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class AgencyWalletDataSource {
  AgencyWalletDataSource(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  Future<AgencyWalletSnapshot?> fetchWallet() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.agencyWallet);
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      return AgencyWalletSnapshot.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> transferToMember({
    required String userId,
    required int amount,
    String? reason,
  }) async {
    if (userId.trim().isEmpty || amount <= 0) return false;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.agencyWalletTransfer,
        data: {
          'userId': userId.trim(),
          'amount': amount,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
          'idempotencyKey': _uuid.v4(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
