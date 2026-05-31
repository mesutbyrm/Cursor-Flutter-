import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/jeton_package_entity.dart';
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

  static bool looksLikeUsernameKey(String id) {
    final s = id.trim();
    if (s.isEmpty || s.length > 64) return false;
    if (s.startsWith('cm') && s.length > 20) return false;
    return RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(s);
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
    if (Env.useNextAuth) {
      final res = await _dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.userCredits,
      );
      final body = res.data ?? {};
      final err = body['error'];
      if (err != null) {
        throw ApiException(err.toString());
      }
      return asInt(
        pick(body, [
          'credits',
          'balance',
          'coins',
          'coinBalance',
          'amount',
          'credit',
        ]),
      );
    }
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.wallet);
    final body = res.data ?? {};
    final v = pick(body, ['balance', 'coins', 'coinBalance', 'amount']);
    return asInt(v);
  }

  /// canlifal.com jeton paketleri / fiyatlar.
  Future<List<JetonPackageEntity>> jetonPackages() async {
    if (!Env.useNextAuth) return const [];
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.jetonCatalog,
    );
    final body = res.data ?? {};
    final err = body['error'];
    if (err != null) {
      throw ApiException(err.toString());
    }
    return _parseJetonPackages(body);
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
        'amount',
        'coinAmount',
        'miktar',
        'balance',
      ]),
    );
    if (coins <= 0 && pick(m, ['price', 'fiyat', 'tl']) == null) {
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
    ])?.toString();
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
      ]),
    );
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
    'products',
    'bundles',
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
