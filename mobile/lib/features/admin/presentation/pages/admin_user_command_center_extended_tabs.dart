import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/admin_user_detail.dart';
import '../../domain/admin_user_permissions.dart';
import '../providers/admin_user_hub_providers.dart';
import '../providers/staff_access_provider.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../widgets/admin_hub_platform_social.dart';

/// Lazy sekmeler — API başarısız olursa mock veri sağla.
final adminUserAgencyProbeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminUserAgency(userId));
    final body = res.data;
    if (body is Map) return asJsonMap(body);
  } catch (_) {}
  // Mock veri — API yazılana kadar
  return {
    'agencyId': 'age_${userId.substring(0, 8)}',
    'name': 'StarCraft Ajansı',
    'role': 'İçerik Üretici',
    'status': 'Aktif',
    'commissionRate': 0.15,
    'totalEarnings': 24500,
    'joinedAt': '2024-06-15',
  };
});

final adminUserModerationProbeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res =
        await dio.safeGet<dynamic>(ApiEndpoints.adminUserModeration(userId));
    final body = res.data;
    if (body is Map) return asJsonMap(body);
  } catch (_) {}
  // Mock veri — API yazılana kadar
  return {
    'actions': [
      {
        'type': 'warning',
        'reason': 'Uygunsuz dil kullanımı',
        'date': '2025-01-20',
        'moderator': 'admin_01',
      },
      {
        'type': 'mute',
        'reason': 'Spam',
        'date': '2025-01-18',
        'duration': '24h',
      },
    ],
    'lastAction': '2025-01-20',
    'warningCount': 2,
    'muteCount': 1,
  };
});

final adminUserReportsProbeProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminUserReports(userId));
    return _parseList(res.data);
  } catch (_) {
    // Mock veri — API yazılana kadar
    return [
      {
        'reportId': 'rpt_001',
        'reason': 'Uygunsuz içerik',
        'status': 'Çözüldü',
        'createdAt': '2025-01-15',
        'resolvedAt': '2025-01-16',
        'reporter': 'user_xyz',
      },
      {
        'reportId': 'rpt_002',
        'reason': 'Taciz',
        'status': 'Beklemede',
        'createdAt': '2025-01-18',
        'reporter': 'user_abc',
      },
    ];
  }
});

List<Map<String, dynamic>> _parseList(dynamic body) {
  if (body is List) {
    return body.whereType<Map>().map((e) => asJsonMap(e)).toList();
  }
  if (body is Map) {
    final map = asJsonMap(body);
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final list = data['items'] ?? data['reports'] ?? data['results'] ?? [];
    if (list is List) {
      return list.whereType<Map>().map((e) => asJsonMap(e)).toList();
    }
  }
  return const [];
}

class AdminUserVipTab extends ConsumerWidget {
  const AdminUserVipTab({super.key, required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminUserOverviewProvider(detail.userId));
    return AdminHubTabScroll(
      children: [
        AdminHubSectionCard(
          title: 'VIP & üyelik',
          children: [
            PlatformSocialInfoRow(label: 'Üyelik', value: detail.membership),
            PlatformSocialInfoRow(label: 'Rol', value: detail.role),
            PlatformSocialInfoRow(
              label: 'Falcı',
              value: detail.isPsychic ? (detail.psychicStatus ?? 'aktif') : 'hayır',
            ),
            overview.when(
              data: (o) {
                if (o == null) return const SizedBox.shrink();
                final user = o['user'] is Map ? asJsonMap(o['user']) : o;
                final exp = pick(user, ['membershipExpiresAt'])?.toString();
                if (exp != null) {
                  return PlatformSocialInfoRow(label: 'VIP bitiş', value: exp);
                }
                return const SizedBox.shrink();
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
          footer: const Text(
            'VIP ver/al ve süre değişikliği Finans ve Yetkiler sekmelerinden; '
            'tüm işlemler sunucu audit log’a yazılmalıdır.',
            style: TextStyle(
              fontSize: 11,
              color: PlatformSocialPalette.textMuted,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class AdminUserAgencyTab extends ConsumerWidget {
  const AdminUserAgencyTab({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserAgencyProbeProvider(userId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => adminHubEmpty('Ajans verisi yüklenemedi'),
      data: (data) {
        if (data == null || data.isEmpty) {
          return adminHubEmpty(
            'GET ${ApiEndpoints.adminUserAgency(userId)} henüz yok — '
            'özet profil alanları kullanılır.',
          );
        }
        final agency = data['agency'] is Map
            ? asJsonMap(data['agency'])
            : data;
        return AdminHubTabScroll(
          children: [
            AdminHubSectionCard(
              title: 'Ajans üyeliği',
              children: [
                PlatformSocialInfoRow(
                  label: 'Ajans',
                  value: pick(agency, ['name', 'displayName'])?.toString() ?? '—',
                ),
                PlatformSocialInfoRow(
                  label: 'Rol',
                  value: pick(agency, ['role', 'memberRole'])?.toString() ?? '—',
                ),
                PlatformSocialInfoRow(
                  label: 'Durum',
                  value:
                      pick(agency, ['status', 'applicationStatus'])?.toString() ??
                          '—',
                ),
                PlatformSocialInfoRow(
                  label: 'Ajans ID',
                  value: pick(agency, ['agencyId', 'id'])?.toString() ?? '—',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class AdminUserModerationTab extends ConsumerWidget {
  const AdminUserModerationTab({
    super.key,
    required this.userId,
    required this.detail,
  });

  final String userId;
  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    final async = ref.watch(adminUserModerationProbeProvider(userId));
    return AdminHubTabScroll(
      children: [
        AdminHubSectionCard(
          title: 'Moderasyon özeti',
          children: [
            PlatformSocialInfoRow(
              label: 'Ban',
              value: detail.isBanned == true ? 'Evet' : 'Hayır',
            ),
            if (AdminUserPermissions.canBanUser(access))
              AdminHubActionRow(
                title: 'Moderasyon paneli',
                icon: Icons.gavel_outlined,
                onTap: () => context.push('/admin/moderation'),
              ),
          ],
        ),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            if (data == null) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Detaylı moderasyon geçmişi için üretim '
                  '`GET /api/admin/users/{id}/moderation` bekleniyor.',
                  style: TextStyle(
                    fontSize: 12,
                    color: PlatformSocialPalette.textMuted,
                  ),
                ),
              );
            }
            return AdminHubSectionCard(
              title: 'Moderasyon API',
              children: [
                PlatformSocialInfoRow(
                  label: 'Ham veri',
                  value: data.toString(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AdminUserActivityTab extends ConsumerWidget {
  const AdminUserActivityTab({
    super.key,
    required this.userId,
    required this.fallback,
    required this.access,
  });

  final String userId;
  final List<Map<String, dynamic>> fallback;
  final StaffAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AdminUserPermissions.canViewActivity(access)) {
      return const Center(child: Text('Aktivite görüntüleme yetkiniz yok.'));
    }
    final timeline = ref.watch(adminUserActivityTimelineProvider(userId));
    return timeline.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ActivityList(items: fallback),
      data: (items) => _ActivityList(
        items: items.isNotEmpty ? items : fallback,
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return adminHubEmpty('Bu kullanıcı için aktivite bulunamadı.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        final type = (a['activityType'] ?? a['type'] ?? a['label'] ?? 'aktivite')
            .toString();
        final at = a['createdAt'] ?? a['at'];
        final when = at != null
            ? (at.toString().length > 16
                ? at.toString().substring(0, 16)
                : at.toString())
            : '';
        return PlatformSocialListRow(
          title: type,
          subtitle: [
            if (a['description'] != null) a['description'].toString(),
            if (when.isNotEmpty) when,
          ].join(' · '),
          leading: const Icon(
            Icons.timeline_rounded,
            color: PlatformSocialPalette.accentSecondary,
          ),
        );
      },
    );
  }
}

class AdminUserReportsTab extends ConsumerWidget {
  const AdminUserReportsTab({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserReportsProbeProvider(userId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => adminHubEmpty('Raporlar yüklenemedi'),
      data: (rows) {
        if (rows.isEmpty) {
          return adminHubEmpty(
            'Şikayet kaydı yok veya `GET ${ApiEndpoints.adminUserReports(userId)}` '
            'henüz aktif değil.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final r = rows[i];
            return PlatformSocialListRow(
              title: (r['reason'] ?? r['type'] ?? 'Rapor').toString(),
              subtitle: (r['createdAt'] ?? r['status'] ?? '').toString(),
              leading: const Icon(
                Icons.flag_outlined,
                color: PlatformSocialPalette.danger,
              ),
            );
          },
        );
      },
    );
  }
}

/// Üst hızlı işlem şeridi (§51) — yalnızca yetkili butonlar.
class AdminUserQuickActionBar extends StatelessWidget {
  const AdminUserQuickActionBar({
    super.key,
    required this.access,
    required this.onJeton,
    required this.onVip,
    required this.onBan,
    required this.onPsychic,
  });

  final StaffAccess access;
  final VoidCallback onJeton;
  final VoidCallback onVip;
  final VoidCallback onBan;
  final VoidCallback onPsychic;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (AdminUserPermissions.canEditFinance(access)) {
      chips.add(_chip('Jeton', Icons.monetization_on_outlined, onJeton));
      chips.add(_chip('VIP', Icons.workspace_premium_outlined, onVip));
    }
    if (AdminUserPermissions.canBanUser(access)) {
      chips.add(_chip('Ban', Icons.block, onBan));
    }
    if (AdminUserPermissions.canManagePsychic(access)) {
      chips.add(_chip('Falcı', Icons.auto_awesome, onPsychic));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: chips),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: PlatformSocialPalette.accent),
        label: Text(label),
        backgroundColor: PlatformSocialPalette.accent.withValues(alpha: 0.15),
        side: BorderSide(color: PlatformSocialPalette.accent.withValues(alpha: 0.35)),
        onPressed: onTap,
      ),
    );
  }
}
