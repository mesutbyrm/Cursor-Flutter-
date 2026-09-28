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

/// `GET /api/admin/users/{id}/360?section=…` — `{success, data: {...}}`.
Future<Map<String, dynamic>?> _fetch360(Ref ref, String path) async {
  final res = await ref.watch(dioProvider).safeGet<dynamic>(path);
  final body = asJsonMap(res.data);
  return body['data'] is Map ? asJsonMap(body['data']) : null;
}

/// `section=agency` → `{membership: AgencyUser+agency, earnings}`; üye değilse null.
final adminUserAgencyProbeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final data = await _fetch360(ref, ApiEndpoints.adminUserAgency(userId));
  final m = data?['membership'];
  return m is Map ? asJsonMap(m) : null;
});

/// `section=moderation` → `{status, warnings, admin_actions, total}`.
final adminUserModerationProbeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>(
  (ref, userId) => _fetch360(ref, ApiEndpoints.adminUserModeration(userId)),
);

/// `section=reports` → `reports_against[]` (şikayet eden `reporter` ile).
final adminUserReportsProbeProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final data = await _fetch360(ref, ApiEndpoints.adminUserReports(userId));
  return asJsonList(data?['reports_against']);
});

String _shortDate(dynamic v) {
  final dt = DateTime.tryParse(v?.toString() ?? '');
  if (dt == null) return '';
  final l = dt.toLocal();
  return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
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
      data: (m) {
        if (m == null) return adminHubEmpty('Kullanıcı bir ajansa üye değil.');
        final agency = asJsonMap(m['agency']);
        return AdminHubTabScroll(
          children: [
            AdminHubSectionCard(
              title: 'Ajans üyeliği',
              children: [
                PlatformSocialInfoRow(
                  label: 'Ajans',
                  value: agency['name']?.toString() ?? '—',
                ),
                PlatformSocialInfoRow(
                  label: 'Rol',
                  value: m['role']?.toString() ?? '—',
                ),
                PlatformSocialInfoRow(
                  label: 'Durum',
                  value: m['isActive'] == false ? 'Ayrıldı' : 'Aktif',
                ),
                PlatformSocialInfoRow(
                  label: 'Katılım',
                  value: _shortDate(m['joinedAt']),
                ),
                PlatformSocialInfoRow(
                  label: 'Ajansa katkı',
                  value: '${m['totalEarnings'] ?? 0}',
                ),
                PlatformSocialInfoRow(
                  label: 'Ajans ID',
                  value: agency['id']?.toString() ?? '—',
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
            if (data == null) return const SizedBox.shrink();
            final warnings = asJsonList(data['warnings']);
            final actions = asJsonList(data['admin_actions']);
            final status = asJsonMap(data['status']);
            return Column(
              children: [
                AdminHubSectionCard(
                  title: 'Durum',
                  children: [
                    PlatformSocialInfoRow(
                      label: 'Uyarı sayısı',
                      value: '${status['warningCount'] ?? warnings.length}',
                    ),
                    if (status['banReason'] != null)
                      PlatformSocialInfoRow(
                        label: 'Ban nedeni',
                        value: status['banReason'].toString(),
                      ),
                    if (status['bannedUntil'] != null)
                      PlatformSocialInfoRow(
                        label: 'Ban bitişi',
                        value: _shortDate(status['bannedUntil']),
                      ),
                    PlatformSocialInfoRow(
                      label: 'Dondurulmuş',
                      value: status['isFrozen'] == true ? 'Evet' : 'Hayır',
                    ),
                  ],
                ),
                AdminHubSectionCard(
                  title: 'Uyarılar (${warnings.length})',
                  children: [
                    if (warnings.isEmpty)
                      const Text(
                        'Uyarı yok.',
                        style: TextStyle(color: PlatformSocialPalette.textMuted),
                      ),
                    for (final w in warnings)
                      PlatformSocialListRow(
                        title: w['reason']?.toString() ?? 'Uyarı',
                        subtitle: [
                          w['severity']?.toString() ?? '',
                          w['adminName']?.toString() ?? '',
                          _shortDate(w['createdAt']),
                        ].where((e) => e.isNotEmpty).join(' · '),
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: PlatformSocialPalette.gold,
                        ),
                      ),
                  ],
                ),
                AdminHubSectionCard(
                  title: 'Yönetici işlemleri (${data['total'] ?? actions.length})',
                  children: [
                    if (actions.isEmpty)
                      const Text(
                        'İşlem kaydı yok.',
                        style: TextStyle(color: PlatformSocialPalette.textMuted),
                      ),
                    for (final a in actions)
                      PlatformSocialListRow(
                        title: a['action']?.toString() ?? 'işlem',
                        subtitle: [
                          a['reason']?.toString() ?? '',
                          a['adminName']?.toString() ?? '',
                          _shortDate(a['createdAt']),
                        ].where((e) => e.isNotEmpty).join(' · '),
                        leading: const Icon(
                          Icons.gavel_outlined,
                          color: PlatformSocialPalette.accent,
                        ),
                      ),
                  ],
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
            if ((a['detail'] ?? a['description']) != null)
              (a['detail'] ?? a['description']).toString(),
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
          return adminHubEmpty('Bu kullanıcı hakkında şikayet yok.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final r = rows[i];
            final reporter = asJsonMap(r['reporter']);
            final by = (reporter['name'] ?? reporter['username'])?.toString();
            return PlatformSocialListRow(
              title: (r['reason'] ?? 'Şikayet').toString(),
              subtitle: [
                if (by != null && by.isNotEmpty) 'Şikayet eden: $by',
                r['status']?.toString() ?? '',
                _shortDate(r['createdAt']),
                if (r['details'] != null) r['details'].toString(),
              ].where((e) => e.isNotEmpty).join(' · '),
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
