import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
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

int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Sunucunun yazdığı Türkçe hata (`{error:{message}}`, `{error:'..'}`, `{message}`).
String serverErrorMessage(Object e, {String fallback = 'İşlem tamamlanamadı'}) {
  if (e is DioException) {
    final body = e.response?.data;
    if (body is Map) {
      final err = body['error'];
      if (err is Map && err['message'] != null) return err['message'].toString();
      if (err is String && err.trim().isNotEmpty) return err;
      final msg = body['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return ApiException.fromDio(e).message;
  }
  if (e is ApiException) return e.message;
  return fallback;
}

/// Ajans → kullanıcı Jeton yükleme sonucu.
class AgencyTransferResult {
  const AgencyTransferResult({required this.ok, required this.message, this.walletBalance});
  final bool ok;
  final String message;
  final double? walletBalance;
}

/// `GET /api/agency/purchase` fiyat teklifi (sunucu hesaplar).
class AgencyPurchaseQuote {
  const AgencyPurchaseQuote({
    required this.jetonAmount,
    required this.normalPriceTl,
    required this.finalPriceTl,
    required this.discountPercent,
    required this.savedTl,
  });

  final int jetonAmount;
  final double normalPriceTl;
  final double finalPriceTl;
  final double discountPercent;
  final double savedTl;

  static AgencyPurchaseQuote fromJson(Map<String, dynamic> m) => AgencyPurchaseQuote(
        jetonAmount: _asInt(m['jetonAmount']),
        normalPriceTl: asDouble(m['normalPriceTl']) ?? 0,
        finalPriceTl: asDouble(m['finalPriceTl']) ?? 0,
        discountPercent: asDouble(m['discountPercent']) ?? 0,
        savedTl: asDouble(m['savedTl']) ?? 0,
      );
}

class AgencyPurchaseOrder {
  const AgencyPurchaseOrder({
    required this.id,
    required this.jeton,
    required this.amountTl,
    required this.status,
    this.createdAt,
    this.note,
  });

  final String id;
  final int jeton;
  final double amountTl;
  final String status;
  final DateTime? createdAt;
  final String? note;

  bool get cancellable => status == 'pending' || status == 'corrected';

  String get statusLabel => switch (status) {
        'pending' => 'Onay bekliyor',
        'corrected' => 'Düzeltildi · onay bekliyor',
        'approved' => 'Onaylandı · cüzdana yüklendi',
        'rejected' => 'Reddedildi',
        'cancelled' => 'İptal edildi',
        'refunded' => 'İade edildi',
        _ => status,
      };

  static AgencyPurchaseOrder fromJson(Map<String, dynamic> m) => AgencyPurchaseOrder(
        id: '${m['id'] ?? ''}',
        jeton: _asInt(m['jetonLoaded'] ?? m['requestedAmount']),
        amountTl: asDouble(m['amount']) ?? 0,
        status: '${m['status'] ?? 'pending'}',
        createdAt: DateTime.tryParse('${m['createdAt'] ?? ''}'),
        note: m['adminNote']?.toString(),
      );
}

class AgencyPurchaseInfo {
  const AgencyPurchaseInfo({
    required this.quote,
    required this.minJeton,
    required this.enabled,
    required this.orders,
  });

  final AgencyPurchaseQuote quote;
  final int minJeton;
  final bool enabled;
  final List<AgencyPurchaseOrder> orders;
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

  /// `POST /api/agency/wallet/transfer` — ajans bakiyesinden kullanıcıya Jeton.
  /// Bakiye yetmezse sunucu "X jeton eksik" der; mesaj aynen döner.
  /// Aynı [idempotencyKey] tekrar gönderilirse ikinci kez aktarılmaz.
  Future<AgencyTransferResult> transfer({
    required String targetUserId,
    required int amount,
    String? reason,
    String? idempotencyKey,
  }) async {
    if (targetUserId.trim().isEmpty || amount <= 0) {
      return const AgencyTransferResult(ok: false, message: 'Kullanıcı ve geçerli bir miktar seçin');
    }
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<dynamic>(
        ApiEndpoints.agencyWalletTransfer,
        data: {
          'targetUserId': targetUserId.trim(),
          'amount': amount,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
          // Kullanıcı uygulamadaki onay penceresinde onayladı.
          'confirm': true,
          'idempotencyKey': key,
        },
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data is Map ? asJsonMap(res.data) : const <String, dynamic>{};
      final data = body['data'] is Map ? asJsonMap(body['data']) : const <String, dynamic>{};
      return AgencyTransferResult(
        ok: body['success'] != false,
        message: body['message']?.toString() ?? '$amount Jeton yüklendi',
        walletBalance: asDouble(data['walletBalance']),
      );
    } catch (e) {
      return AgencyTransferResult(ok: false, message: serverErrorMessage(e, fallback: 'Yükleme yapılamadı'));
    }
  }

  /// Geriye uyum: üye satırındaki eski çağrı.
  Future<bool> transferToMember({
    required String userId,
    required int amount,
    String? reason,
  }) async =>
      (await transfer(targetUserId: userId, amount: amount, reason: reason)).ok;

  Future<AgencyPurchaseInfo> fetchPurchase({int? jeton}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.agencyPurchase,
      query: {if (jeton != null && jeton > 0) 'jeton': jeton},
    );
    final body = asJsonMap(res.data);
    final data = body['data'] is Map ? asJsonMap(body['data']) : body;
    final limits = data['limits'] is Map ? asJsonMap(data['limits']) : const <String, dynamic>{};
    final rawOrders = data['orders'];
    return AgencyPurchaseInfo(
      quote: AgencyPurchaseQuote.fromJson(
        data['quote'] is Map ? asJsonMap(data['quote']) : const {},
      ),
      minJeton: _asInt(limits['minJeton'] ?? 1000),
      enabled: limits['enabled'] != false,
      orders: rawOrders is List
          ? rawOrders.whereType<Map>().map((e) => AgencyPurchaseOrder.fromJson(asJsonMap(e))).toList()
          : const [],
    );
  }

  /// `POST /api/agency/purchase` — ödeme bildirimiyle toplu Jeton siparişi.
  /// Tutarı sunucu hesaplar; Jeton admin onayından sonra cüzdana geçer.
  Future<void> createPurchase({
    required int jeton,
    required String paymentMethod,
    String? transactionId,
    String? senderName,
    String? notes,
  }) async {
    final key = _uuid.v4();
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.agencyPurchase,
        data: {
          'jeton': jeton,
          'paymentMethod': paymentMethod,
          if (transactionId != null && transactionId.trim().isNotEmpty) 'transactionId': transactionId.trim(),
          if (senderName != null && senderName.trim().isNotEmpty) 'senderName': senderName.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
        options: Options(headers: {'Idempotency-Key': key}),
      );
    } catch (e) {
      throw ApiException(serverErrorMessage(e, fallback: 'Sipariş oluşturulamadı'));
    }
  }

  /// Bekleyen ödeme bildirimini (ajans siparişi dahil) iptal eder.
  Future<void> cancelPaymentNotification(String id, {String? reason}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.paymentNotificationCancel(id),
        data: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
      );
    } catch (e) {
      throw ApiException(serverErrorMessage(e, fallback: 'İptal edilemedi'));
    }
  }
}
