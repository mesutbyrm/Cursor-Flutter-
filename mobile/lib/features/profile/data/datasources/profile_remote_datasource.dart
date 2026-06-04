import 'package:dio/dio.dart';

import '../../../../core/pagination/paged_result.dart';
import '../../../../core/config/env.dart';
import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/payment_debug_log.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../jeton_packages_catalog.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
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
    Object? lastError;
    for (final path in [
      ApiEndpoints.follow(userId),
      ApiEndpoints.userFollow(userId),
    ]) {
      try {
        await _dio.safePost(path);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw ApiException.userMessage(lastError ?? 'Takip edilemedi');
  }

  Future<void> unfollow(String userId) async {
    if (Env.useMobileAuth) {
      await _dio.safePost(ApiEndpoints.follow(userId));
      return;
    }
    await _dio.safeDelete(ApiEndpoints.follow(userId));
  }

  Future<UserEntity> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? username,
    String? currentPassword,
    String? newPassword,
  }) async {
    final res = await _dio.safePatch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {
        if (displayName != null) ...{
          'name': displayName,
          'displayName': displayName,
        },
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) ...{
          'image': avatarUrl,
          'avatarUrl': avatarUrl,
        },
        if (username != null) 'username': username,
        if (currentPassword != null) 'currentPassword': currentPassword,
        if (newPassword != null) 'newPassword': newPassword,
      },
    );
    final body = res.data ?? {};
    final data = body['data'] is Map ? asJsonMap(body['data']) : body;
    return UserDto.fromApiMap(data).toEntity();
  }

  Future<ProfileStatsEntity> myStats() async {
    try {
      final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.meStats);
      return ProfileStatsEntity.fromJson(res.data ?? {});
    } catch (_) {
      return const ProfileStatsEntity();
    }
  }

  Future<List<GiftReceivedSummaryEntity>> giftsReceivedSummary() async {
    try {
      final res =
          await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.meGiftsReceived);
      final body = res.data ?? {};
      final data = body['data'] is Map ? asJsonMap(body['data']) : body;
      final raw = data['summary'];
      if (raw is! List) return const [];
      return raw
          .map((e) => GiftReceivedSummaryEntity.fromJson(asJsonMap(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<BroadcastHistoryItemEntity>> broadcastHistory() async {
    try {
      final res = await _dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.meBroadcastHistory,
      );
      final body = res.data ?? {};
      final data = body['data'] is Map ? asJsonMap(body['data']) : body;
      final raw = data['items'];
      if (raw is! List) return const [];
      return raw
          .map((e) => BroadcastHistoryItemEntity.fromJson(asJsonMap(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ProfileActivityItemEntity>> myActivity() async {
    try {
      final res =
          await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.meActivity);
      final body = res.data ?? {};
      final data = body['data'] is Map ? asJsonMap(body['data']) : body;
      final raw = data['items'];
      if (raw is! List) return const [];
      return raw
          .map((e) => ProfileActivityItemEntity.fromJson(asJsonMap(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<UserEntity>> followers(String userId) async {
    for (final path in [
      ApiEndpoints.userPublicFollowers(userId),
      if (Env.useMobileAuth) ApiEndpoints.userFollowers,
      ApiEndpoints.followers(userId),
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          query: const {'page': 1, 'limit': 50},
        );
        final list = _parseUserList(res.data);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  Future<List<UserEntity>> following(String userId) async {
    for (final path in [
      if (Env.useMobileAuth) ApiEndpoints.userFollowing,
      ApiEndpoints.following(userId),
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          query: const {'page': 1, 'limit': 50},
        );
        final list = _parseUserList(res.data);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  List<UserEntity> _parseUserList(dynamic body) {
    if (body is List) {
      return asJsonList(body)
          .map((e) => UserDto.fromApiMap(asJsonMap(e)).toEntity())
          .where((u) => u.id.isNotEmpty)
          .toList();
    }
    if (body is! Map) return const [];
    final data = body['data'] is Map ? asJsonMap(body['data']) : asJsonMap(body);
    final raw =
        data['followers'] ?? data['following'] ?? data['users'] ?? data['items'];
    if (raw is! List) return const [];
    return raw.map((e) => UserDto.fromApiMap(asJsonMap(e)).toEntity()).toList();
  }
}

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  Future<int> balance() async {
    final b = await balances();
    return b.jeton;
  }

  Future<WalletBalances> balances() async {
    if (!Env.useMobileAuth) {
      final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.wallet);
      return WalletBalances.fromJson(_unwrap(res.data));
    }

    Object? lastError;
    for (final path in [ApiEndpoints.me, ApiEndpoints.userCredits]) {
      try {
        final res = await _dio
            .safeGet<Map<String, dynamic>>(path)
            .timeout(const Duration(seconds: 18));
        final body = res.data ?? {};
        final err = body['error'];
        if (err != null && err.toString().trim().isNotEmpty) {
          throw ApiException(err.toString());
        }
        final map = _unwrap(body);
        if (map.containsKey('user') && map['user'] is Map) {
          return WalletBalances.fromJson(asJsonMap(map['user']));
        }
        return WalletBalances.fromJson(map);
      } on Object catch (e) {
        lastError = e;
      }
    }
    throw ApiException(
      lastError != null
          ? ApiException.userMessage(lastError)
          : 'Bakiye alınamadı. Oturumu kontrol edin.',
    );
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
      return PaymentDefaults.config;
    }
    final remote = PaymentConfigEntity.fromJson(_unwrap(data));
    return PaymentDefaults.merge(remote);
  }

  bool _paymentRequestAccepted(dynamic data, int code) {
    if (code == 201 || code == 200) {
      if (data == null) return true;
      if (data is String && data.trim().isEmpty) return true;
    }
    if (data is! Map) return false;
    final m = Map<String, dynamic>.from(data);
    if (m['success'] == true) return true;
    if (m['id'] != null || m['paymentRequestId'] != null) return true;
    final nested = m['data'];
    if (nested is Map) {
      final inner = Map<String, dynamic>.from(nested);
      if (inner['id'] != null || inner['paymentRequestId'] != null) {
        return true;
      }
      if (inner['request'] is Map) {
        final r = Map<String, dynamic>.from(inner['request'] as Map);
        if (r['id'] != null) return true;
      }
    }
    if (m['request'] is Map) {
      final r = Map<String, dynamic>.from(m['request'] as Map);
      if (r['id'] != null) return true;
    }
    return false;
  }

  static const _paymentTimeout = Duration(seconds: 45);

  Options _paymentPostOptions() => Options(
        contentType: 'application/json',
        receiveTimeout: _paymentTimeout,
        sendTimeout: const Duration(seconds: 25),
        headers: const {'Accept': 'application/json'},
      );

  Future<Response<dynamic>> _postPaymentRequest(
    String path,
    Map<String, dynamic> body,
  ) async {
    final started = DateTime.now();
    PaymentDebugLog.log('submitStart', {
      'path': path,
      'baseUrl': Env.apiBaseUrl,
      'timeoutSec': _paymentTimeout.inSeconds,
      'bodyKeys': body.keys.join(','),
    });
    try {
      final res = await _dio.safePost<dynamic>(
        path,
        data: body,
        options: _paymentPostOptions(),
      );
      PaymentDebugLog.log('submitDone', {
        'path': path,
        'status': res.statusCode,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      });
      return res;
    } on ApiException catch (e) {
      PaymentDebugLog.log('submitFailed', {
        'path': path,
        'status': e.statusCode,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
        'message': e.message,
      });
      rethrow;
    }
  }

  Future<void> submitPaymentRequest(Map<String, dynamic> body) async {
    final access = await _tokens.readAccess();
    final hasJwt = access != null &&
        access.isNotEmpty &&
        access != TokenStorage.sessionCookieMarker;
    PaymentDebugLog.log('jwtStatus', {
      'hasAccessToken': hasJwt,
      'useMobileAuth': Env.useMobileAuth,
    });
    if (!hasJwt) {
      throw const ApiException(
        'Oturum bulunamadı. Çıkış yapıp tekrar giriş yapın, ardından ödemeyi deneyin.',
      );
    }

    Response<dynamic> res;
    try {
      res = await _postPaymentRequest(ApiEndpoints.paymentRequests, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      res = await _postPaymentRequest('/api/jeton/payment-request', body);
    }

    final code = res.statusCode ?? 0;
    final data = res.data;

    if (code >= 400) {
      String msg = 'Talep gönderilemedi (HTTP $code).';
      if (data is Map) {
        msg = (data['error'] ?? data['message'] ?? msg).toString();
      } else if (data is String && data.isNotEmpty && !data.contains('<html')) {
        msg = data;
      }
      throw ApiException(msg, statusCode: code);
    }

    if (_paymentRequestAccepted(data, code)) return;
    if (data is String) {
      final s = data.trim();
      if (s.contains('<!DOCTYPE') || s.contains('<html')) {
        throw const ApiException(
          'Ödeme talebi gönderilemedi — sunucu oturum sayfası döndürdü. '
          'Çıkış yapıp tekrar giriş yapın.',
        );
      }
      if (s.isNotEmpty) {
        throw ApiException(s);
      }
      return;
    }

    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m['success'] == false) {
        throw ApiException(
          (m['error'] ?? m['message'] ?? 'Talep gönderilemedi').toString(),
        );
      }
      final err = m['error'];
      if (err != null && err.toString().isNotEmpty) {
        throw ApiException(err.toString());
      }
    }

    throw const ApiException(
      'Ödeme bildirimi sunucudan onay alınamadı. '
      'Bildirimler veya talep geçmişinden kontrol edin; gerekirse tekrar deneyin.',
    );
  }

  Future<List<CfcPaymentRequestEntity>> myPaymentRequests() async {
    final page = await myPaymentRequestsPage(page: 1);
    return page.items;
  }

  Future<PagedResult<CfcPaymentRequestEntity>> myPaymentRequestsPage({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.paymentRequests,
      query: {'page': page, 'limit': limit},
    );
    dynamic data = res.data;
    if (data is Map && data['success'] == true) data = data['data'];
    List<dynamic> raw = const [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final m = asJsonMap(data);
      raw = asJsonList(m['requests'] ?? m['items'] ?? const []);
    } else if (res.data is Map) {
      final m = asJsonMap(res.data);
      raw = asJsonList(m['requests'] ?? m['items'] ?? const []);
    }
    final items = raw
        .map((e) => CfcPaymentRequestEntity.fromJson(asJsonMap(e)))
        .toList();
    var hasMore = items.length >= limit;
    final body = res.data;
    if (body is Map) {
      final pag = body['pagination'] ??
          (body['data'] is Map ? asJsonMap(body['data'])['pagination'] : null);
      if (pag is Map) {
        final pm = asJsonMap(pag);
        final totalPages = asInt(pm['totalPages']);
        final current = asInt(pm['page']);
        if (totalPages > 0) hasMore = current < totalPages;
      }
    }
    return PagedResult(items: items, hasMore: hasMore);
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
    if (Env.useMobileAuth) {
      final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.me);
      final body = res.data ?? {};
      final err = body['error'];
      if (err != null) {
        throw ApiException(err.toString());
      }
      final merged = Map<String, dynamic>.from(body);
      final code = pick(body, ['referralCode', 'referral_code'])?.toString();
      if (code != null && code.trim().isNotEmpty) {
        merged['code'] = code.trim();
      }
      final invited = asInt(
        pick(body, ['referralCreditsEarned', 'referral_credits_earned']),
      );
      if (invited > 0) merged['invitedCount'] = invited;
      return _parseReferral(merged);
    }
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
