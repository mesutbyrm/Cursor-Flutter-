import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/admin_user_detail.dart';
import '../../domain/admin_user_permissions.dart';
import '../providers/staff_access_provider.dart';

/// Lazy sekmeler — üretim uçları yoksa boş durum + probe mesajı (§49).
final adminUserAgencyProbeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminUserAgency(userId));
    final body = res.data;
    if (body is Map) return asJsonMap(body);
  } catch (_) {}
  return null;
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
  return null;
});

final adminUserReportsProbeProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminUserReports(userId));
    return _parseList(res.data);
  } catch (_) {
    return const [];
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

class AdminUserVipTab extends StatelessWidget {
  const AdminUserVipTab({super.key, required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _info('Üyelik', detail.membership),
        _info('Rol', detail.role),
        _info('Falcı', detail.isPsychic ? (detail.psychicStatus ?? 'aktif') : 'hayır'),
        const SizedBox(height: 16),
        const Text(
          'VIP ver/al ve süre değişikliği Finans ve Yetkiler sekmelerinden; '
          'tüm işlemler sunucu audit log’a yazılmalıdır.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
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
      error: (e, _) => _empty('Ajans verisi yüklenemedi'),
      data: (data) {
        if (data == null || data.isEmpty) {
          return _empty(
            'GET ${ApiEndpoints.adminUserAgency(userId)} henüz yok — '
            'özet profil alanları kullanılır.',
          );
        }
        final agency = data['agency'] is Map
            ? asJsonMap(data['agency'])
            : data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _info('Ajans', pick(agency, ['name', 'displayName'])?.toString()),
            _info('Rol', pick(agency, ['role', 'memberRole'])?.toString()),
            _info('Durum', pick(agency, ['status', 'applicationStatus'])?.toString()),
            _info('Ajans ID', pick(agency, ['agencyId', 'id'])?.toString()),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _info('Ban', detail.isBanned == true ? 'Evet' : 'Hayır'),
        if (AdminUserPermissions.canBanUser(access))
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Moderasyon paneli'),
            onTap: () => context.push('/admin/moderation'),
          ),
        const Divider(),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            if (data == null) {
              return const Text(
                'Detaylı moderasyon geçmişi için üretim '
                '`GET /api/admin/users/{id}/moderation` bekleniyor.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              );
            }
            return Text(data.toString());
          },
        ),
      ],
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
      error: (e, _) => _empty('Raporlar yüklenemedi'),
      data: (rows) {
        if (rows.isEmpty) {
          return _empty(
            'Şikayet kaydı yok veya `GET ${ApiEndpoints.adminUserReports(userId)}` '
            'henüz aktif değil.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              title: Text(
                (r['reason'] ?? r['type'] ?? 'Rapor').toString(),
              ),
              subtitle: Text(
                (r['createdAt'] ?? r['status'] ?? '').toString(),
              ),
            );
          },
        );
      },
    );
  }
}

Widget _empty(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    ),
  );
}

Widget _info(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Colors.white54)),
        ),
        Expanded(
          child: Text(
            value?.trim().isNotEmpty == true ? value! : '—',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
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
        avatar: Icon(icon, size: 18, color: AppThemeColors.accentPink),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
