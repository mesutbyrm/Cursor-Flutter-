import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../jeton_packages_catalog.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/referral_info_entity.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserEntity> user(String userId) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.userProfile(userId),
    );
    final body = res.data ?? {};
    final u = pick(body, ['user', 'data', 'profile']);
    final map = u is Map ? asJsonMap(u) : body;
    return UserDto.fromJson(map).toEntity();
  }

  /// canlifal.com oturumlu kullanıcı — takipçi, bio, avatar (NextAuth çerezi).
  Future<UserEntity> mySiteProfile() async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.userSiteProfile,
    );
    final body = res.data ?? {};
    final err = body['error'];
    if (err != null) {
      throw ApiException(err.toString());
    }
    return UserDto.fromSiteProfileMap(body).toEntity();
  }

  Future<void> follow(String userId) async {
    await _dio.safePost(ApiEndpoints.follow(userId));
  }

  Future<void> unfollow(String userId) async {
    await _dio.safeDelete(ApiEndpoints.follow(userId));
  }
}

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._dio);

  final Dio _dio;

  Future<int> balance() async {
    final b = await balances();
    return b.jeton;
  }

  Future<WalletBalances> balances() async {
    if (Env.useNextAuth) {
      final res = await _dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.userCredits,
      );
      final body = _unwrap(res.data);
      final err = body['error'];
      if (err != null) {
        throw ApiException(err.toString());
      }
      return WalletBalances.fromJson(body);
    }
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.wallet);
    return WalletBalances.fromJson(_unwrap(res.data));
  }

  /// Site ödeme ayarları — API dolu alanları korur, yalnız boş alanları tamamlar.
  Future<PaymentConfigEntity> paymentConfig() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.paymentConfig);
    final data = res.data;
    if (data is String &&
        (data.contains('<!DOCTYPE') || data.contains('<html'))) {
      throw const ApiException(
        'Ödeme ayarları alınamadı (sunucu HTML döndürdü). Oturumu kontrol edin.',
      );
    }
    if (data is! Map) {
      throw const ApiException('Ödeme ayarları okunamadı');
    }
    final remote = PaymentConfigEntity.fromJson(_unwrap(data));
    if (remote.whatsappNumber.trim().isEmpty &&
        remote.paparaAddress.trim().isEmpty &&
        remote.bankIban.trim().isEmpty) {
      throw const ApiException('Ödeme bilgileri sitede tanımlı değil');
    }
    return PaymentDefaults.merge(remote);
  }

  Future<void> submitPaymentRequest(Map<String, dynamic> body) async {
    await _dio.safePost(ApiEndpoints.paymentRequests, data: body);
  }

  Future<List<CfcPaymentRequestEntity>> myPaymentRequests() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.paymentRequests);
    dynamic data = res.data;
    if (data is Map && data['success'] == true) data = data['data'];
    if (data is List) {
      return data
          .map((e) => CfcPaymentRequestEntity.fromJson(asJsonMap(e)))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return asJsonMap(data['data']);
    }
    return data is Map ? asJsonMap(data) : {};
  }

  /// canlifal.com jeton paketleri / fiyatlar.
  Future<List<JetonPackageEntity>> jetonPackages() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.jetonCatalog);
      final parsed = _parseJetonResponse(res.data);
      if (parsed.isNotEmpty) return parsed;
    } on ApiException catch (_) {
      // 401 / ağ / 404 / sunucu: varsayılan paketlerle devam et
    } catch (_) {
      // Beklenmeyen yanıt
    }
    return List<JetonPackageEntity>.from(kFallbackJetonPackages);
  }

  List<JetonPackageEntity> _parseJetonResponse(dynamic data) {
    if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        return const [];
      }
      return const [];
    }
    if (data is List) {
      return _parseJetonPackages({'packages': data});
    }
    if (data is! Map) return const [];

    final map = asJsonMap(data);
    final err = map['error'] ?? map['message'];
    if (err != null && err.toString().trim().isNotEmpty) {
      return const [];
    }

    if (map['success'] == true && map['data'] != null) {
      final inner = map['data'];
      if (inner is List) {
        return _parseJetonPackages({'packages': inner});
      }
      if (inner is Map) return _parseJetonPackages(asJsonMap(inner));
    }
    return _parseJetonPackages(map);
  }

  /// Davet bağlantısı veya kod.
  Future<ReferralInfoEntity> referralInfo() async {
    if (!Env.useNextAuth) {
      return ReferralInfoEntity(shareUrl: '${Env.siteOrigin}/davet');
    }
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.referral,
    );
    final body = res.data ?? {};
    final err = body['error'];
    if (err != null) {
      throw ApiException(err.toString());
    }
    return _parseReferral(body);
  }
}

List<JetonPackageEntity> _parseJetonPackages(Map<String, dynamic> body) {
  final raw = _jetonListRoot(body);
  final out = <JetonPackageEntity>[];
  var i = 0;
  for (final m in raw) {
    final id = pick(m, ['id', 'sku', 'key', 'packageId', 'slug'])?.toString() ??
        'pkg_$i';
    final coins = asInt(
      pick(m, [
        'coins',
        'credits',
        'jeton',
        'jetonAmount',
        'amount',
        'coinAmount',
        'miktar',
        'balance',
        'value',
        'quantity',
      ]),
    );
    final priceTry = _asDouble(
      pick(m, [
        'priceTry',
        'price',
        'try',
        'tl',
        'amountTry',
        'fiyat',
        'cost',
        'tutar',
        'priceTl',
      ]),
    );
    if (coins <= 0 && priceTry == null && pick(m, ['priceLabel', 'fiyatMetni']) == null) {
      i++;
      continue;
    }
    final title = pick(m, ['title', 'name', 'label', 'baslik', 'description'])
            ?.toString()
            .trim() ??
        (coins > 0 ? '$coins jeton' : 'Paket');
    final priceLabel = pick(m, [
      'priceLabel',
      'priceText',
      'displayPrice',
      'fiyatMetni',
      'formattedPrice',
    ])?.toString();
    final badge = pick(m, ['badge', 'bonus', 'etiket', 'tag'])?.toString();
    out.add(
      JetonPackageEntity(
        id: id,
        title: title,
        coins: coins > 0 ? coins : 0,
        priceTry: priceTry,
        priceLabel: priceLabel?.isNotEmpty == true ? priceLabel : null,
        badge: badge?.isNotEmpty == true ? badge : null,
      ),
    );
    i++;
  }
  return out;
}

List<Map<String, dynamic>> _jetonListRoot(Map<String, dynamic> body) {
  final direct = pick(body, [
    'packages',
    'items',
    'plans',
    'data',
    'options',
    'paketler',
    'jetonlar',
    'jetonPackages',
    'products',
    'bundles',
    'catalog',
    'list',
  ]);
  if (direct is List) return asJsonList(direct);
  if (direct is Map) {
    final map = asJsonMap(direct);
    final inner = pick(map, ['packages', 'items', 'list', 'rows']);
    if (inner is List) return asJsonList(inner);
  }
  for (final k in body.keys) {
    final v = body[k];
    if (v is List && v.isNotEmpty && v.first is Map) {
      return asJsonList(v);
    }
  }
  return const [];
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}

ReferralInfoEntity _parseReferral(Map<String, dynamic> body) {
  final link = pick(body, [
    'url',
    'link',
    'inviteUrl',
    'referralLink',
    'shareUrl',
    'davetLinki',
    'referralUrl',
  ])?.toString();
  final code = pick(body, [
    'code',
    'referralCode',
    'inviteCode',
    'referral',
    'davetKodu',
  ])?.toString();
  final headline = pick(body, ['headline', 'title', 'message', 'aciklama'])
      ?.toString();
  final rewardHint =
      pick(body, ['reward', 'rewardHint', 'odul', 'bonusText'])?.toString();
  final invited = asInt(
    pick(body, [
      'invitedCount',
      'referrals',
      'count',
      'totalInvites',
      'davetSayisi',
    ]),
  );
  final origin = Env.siteOrigin;
  String shareUrl = link?.trim() ?? '';
  if (shareUrl.isEmpty && code != null && code.trim().isNotEmpty) {
    shareUrl = '$origin/davet?ref=${Uri.encodeQueryComponent(code.trim())}';
  }
  if (shareUrl.isEmpty) {
    shareUrl = '$origin/davet';
  }
  if (!shareUrl.startsWith('http')) {
    shareUrl = shareUrl.startsWith('/')
        ? '$origin$shareUrl'
        : '$origin/$shareUrl';
  }
  return ReferralInfoEntity(
    code: code?.trim().isNotEmpty == true ? code!.trim() : null,
    shareUrl: shareUrl,
    headline: headline?.isNotEmpty == true ? headline : null,
    invitedCount: invited > 0 ? invited : null,
    rewardHint: rewardHint?.isNotEmpty == true ? rewardHint : null,
  );
}
