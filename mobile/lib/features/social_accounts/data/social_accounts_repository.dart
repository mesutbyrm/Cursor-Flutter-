import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

/// Sitenin resmi sosyal medya hesabı (admin panelinden yönetilir).
class SiteSocialAccount {
  const SiteSocialAccount({
    required this.platform,
    required this.label,
    required this.url,
    this.value = '',
    this.handle,
    this.enabled = true,
  });

  factory SiteSocialAccount.fromJson(Map<String, dynamic> j) {
    final platform = (j['platform'] ?? '').toString();
    return SiteSocialAccount(
      platform: platform,
      label: (j['label'] ?? socialPlatformLabel(platform)).toString(),
      url: (j['url'] ?? '').toString(),
      value: (j['value'] ?? j['handle'] ?? '').toString(),
      handle: j['handle']?.toString(),
      enabled: j['enabled'] != false,
    );
  }

  final String platform;
  final String label;
  final String url;
  final String value;
  final String? handle;
  final bool enabled;
}

/// Sunucu `lib/social-accounts.ts` ile aynı sıra.
const kSocialPlatforms = <(String, String)>[
  ('instagram', 'Instagram'),
  ('tiktok', 'TikTok'),
  ('youtube', 'YouTube'),
  ('x', 'X (Twitter)'),
  ('facebook', 'Facebook'),
  ('telegram', 'Telegram'),
  ('whatsapp', 'WhatsApp'),
  ('website', 'Web sitesi'),
];

String socialPlatformLabel(String id) =>
    kSocialPlatforms.where((p) => p.$1 == id).map((p) => p.$2).firstOrNull ??
    id;

IconData socialPlatformIcon(String id) => switch (id) {
      'instagram' => Icons.camera_alt_outlined,
      'tiktok' => Icons.music_note_rounded,
      'youtube' => Icons.play_circle_outline_rounded,
      'x' => Icons.tag_rounded,
      'facebook' => Icons.facebook_rounded,
      'telegram' => Icons.send_rounded,
      'whatsapp' => Icons.chat_rounded,
      _ => Icons.public_rounded,
    };

class SocialAccountsRepository {
  SocialAccountsRepository(this._dio);

  final Dio _dio;

  static List<SiteSocialAccount> _list(dynamic body) {
    final raw = body is Map ? body['accounts'] : null;
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) SiteSocialAccount.fromJson(Map<String, dynamic>.from(e)),
    ].where((a) => a.platform.isNotEmpty).toList();
  }

  /// `GET /api/social-accounts` — yalnız etkin hesaplar.
  Future<List<SiteSocialAccount>> fetchPublic() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.socialAccounts);
    return _list(res.data).where((a) => a.url.startsWith('http')).toList();
  }

  /// `GET /api/admin/social-accounts` — admin; tümü (kapalılar dahil).
  Future<List<SiteSocialAccount>> fetchAdmin() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.adminSocialAccounts);
    return _list(res.data);
  }

  /// `PUT /api/admin/social-accounts` — boş değer o hesabı kaldırır.
  Future<List<SiteSocialAccount>> saveAdmin(
    List<({String platform, String value, bool enabled})> rows,
  ) async {
    final res = await _dio.safePut<dynamic>(
      ApiEndpoints.adminSocialAccounts,
      data: {
        'accounts': [
          for (final r in rows)
            {'platform': r.platform, 'value': r.value.trim(), 'enabled': r.enabled},
        ],
      },
    );
    final body = res.data;
    if (body is Map && body['success'] != true && body['error'] != null) {
      throw ApiException(body['error'].toString());
    }
    return _list(body);
  }
}

final socialAccountsRepositoryProvider =
    Provider<SocialAccountsRepository>((ref) {
  return SocialAccountsRepository(ref.watch(dioProvider));
});

/// Ana sayfa / yardım için herkese açık hesaplar. Hata → boş liste.
final siteSocialAccountsProvider =
    FutureProvider<List<SiteSocialAccount>>((ref) async {
  try {
    return await ref.read(socialAccountsRepositoryProvider).fetchPublic();
  } catch (_) {
    return const [];
  }
});
