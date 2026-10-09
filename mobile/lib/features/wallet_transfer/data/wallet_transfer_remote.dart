import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../gifts/data/gift_idempotency.dart';

enum TransferCurrency { jeton, cfc }

extension TransferCurrencyX on TransferCurrency {
  String get wire => this == TransferCurrency.cfc ? 'cfc' : 'jeton';
  String get label => this == TransferCurrency.cfc ? 'CFC' : 'Jeton';
}

/// Sunucu kuralları: en az miktar + komisyon yüzdesi (admin panelinden).
class TransferRule {
  const TransferRule({this.min = 100, this.commissionPercent = 0});
  final int min;
  final int commissionPercent;

  int commissionFor(int amount) => (amount * commissionPercent) ~/ 100;
  int netFor(int amount) => amount - commissionFor(amount);
}

class TransferRules {
  const TransferRules({
    this.jeton = const TransferRule(),
    this.cfc = const TransferRule(),
  });
  final TransferRule jeton;
  final TransferRule cfc;
  TransferRule of(TransferCurrency c) => c == TransferCurrency.cfc ? cfc : jeton;
}

class TransferResult {
  const TransferResult({
    required this.received,
    required this.commission,
    this.balance,
  });
  final int received;
  final int commission;
  final int? balance;
}

class WalletTransferRemote {
  WalletTransferRemote(this._dio);
  final Dio _dio;

  static int _int(dynamic v, int d) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? d;

  /// `GET /api/wallet/transfer` — hata olursa güvenli varsayılan (min 100, %0).
  Future<TransferRules> fetchRules() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.walletTransfer);
      final body = res.data;
      final data = body is Map ? (body['data'] ?? body) : null;
      if (data is! Map) return const TransferRules();
      TransferRule rule(dynamic m) => m is Map
          ? TransferRule(
              min: _int(m['min'], 100).clamp(1, 1 << 30),
              commissionPercent: _int(m['commissionPercent'], 0).clamp(0, 100),
            )
          : const TransferRule();
      return TransferRules(jeton: rule(data['jeton']), cfc: rule(data['cfc']));
    } catch (_) {
      return const TransferRules();
    }
  }

  /// `POST /api/wallet/transfer` — sunucu bakiyeyi atomik düşer.
  Future<TransferResult> send({
    required String recipient,
    required TransferCurrency currency,
    required int amount,
    String? idempotencyKey,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        ApiEndpoints.walletTransfer,
        data: {
          'recipient': recipient,
          'currency': currency.wire,
          'amount': amount,
        },
        options: giftIdempotentPostOptions(idempotencyKey),
      );
      final body = res.data;
      final data = body is Map ? body['data'] : null;
      if (body is Map && body['success'] == true && data is Map) {
        return TransferResult(
          received: _int(data['received'], amount),
          commission: _int(data['commission'], 0),
          balance: data['balance'] == null ? null : _int(data['balance'], 0),
        );
      }
      throw ApiException(
        (body is Map ? body['error'] : null)?.toString() ??
            'İşlem tamamlanamadı',
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = body is Map ? body['error']?.toString() : null;
      throw ApiException(
        msg ?? 'İşlem tamamlanamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final walletTransferRemoteProvider = Provider<WalletTransferRemote>((ref) {
  return WalletTransferRemote(ref.watch(dioProvider));
});

final walletTransferRulesProvider =
    FutureProvider.autoDispose<TransferRules>((ref) {
  return ref.read(walletTransferRemoteProvider).fetchRules();
});
