import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_user_manage_sheet.dart';
import '../widgets/admin_user_picker.dart';

/// Admin — kullanıcı arama ve yönetim.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return _locked(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Kullanıcı Yönetimi',
                      subtitle: 'Ara, düzenle, jeton/CFC, üyelik',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text(
                    'Kullanıcı adı veya e-posta ile arayın; profil, rol ve bakiye güncelleyin.',
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _pickAndManage(context, ref),
                    icon: const Icon(Icons.person_search_rounded),
                    label: const Text('Kullanıcı Ara'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentPurple,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndManage(BuildContext context, WidgetRef ref) async {
    final user = await AdminUserPicker.show(context, ref);
    if (user == null || !context.mounted) return;
    await AdminUserManageSheet.show(context, ref: ref, user: user);
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Bu alan yalnızca admin veya yönetici hesapları içindir.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

/// Admin — site aktivite raporları.
class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _future = _load());
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final remote = ref.read(adminRemoteProvider);
    return remote.fetchActivities(limit: 100).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw ApiException('timeout', statusCode: 408),
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Bu alan yalnızca admin veya yönetici hesapları içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Raporlar',
                      subtitle: 'Son site aktiviteleri',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (_future == null ||
                      snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: DiscoverAccentLoader());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.error_outline_rounded,
                        message: ApiException.userMessage(snap.error!),
                        actionLabel: 'Yenile',
                        action: _refresh,
                      ),
                    );
                  }
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return const Center(
                      child: DiscoverEmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'Henüz aktivite kaydı yok.',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final type = r['activityType']?.toString() ?? '—';
                      final user = r['userName'] ??
                          r['username'] ??
                          r['displayName'] ??
                          '—';
                      final at = r['createdAt']?.toString() ?? '';
                      return ListTile(
                        leading: const Icon(Icons.timeline_rounded),
                        title: Text(user.toString()),
                        subtitle: Text('$type · $at'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin — moderasyon kuyruğu (şikayet / risk aktiviteleri).
class AdminModerationPage extends ConsumerStatefulWidget {
  const AdminModerationPage({super.key});

  @override
  ConsumerState<AdminModerationPage> createState() =>
      _AdminModerationPageState();
}

class _AdminModerationPageState extends ConsumerState<AdminModerationPage> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _future = _load());
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final remote = ref.read(adminRemoteProvider);
    final rows = await remote.fetchActivities(limit: 100).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw ApiException('timeout', statusCode: 408),
    );
    return rows.where((a) {
      final type = (a['activityType'] ?? '').toString().toLowerCase();
      return type.contains('report') ||
          type.contains('ban') ||
          type.contains('kick') ||
          type.contains('moderation') ||
          type.contains('block');
    }).toList(growable: false);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Bu alan yalnızca admin veya yönetici hesapları içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Moderasyon',
                      subtitle: 'Şikayet ve moderasyon kayıtları',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (_future == null ||
                      snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: DiscoverAccentLoader());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.error_outline_rounded,
                        message: ApiException.userMessage(snap.error!),
                        actionLabel: 'Yenile',
                        action: _refresh,
                      ),
                    );
                  }
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.gavel_rounded,
                        message:
                            'Bekleyen moderasyon kaydı yok.\nSesli oda ve yayın moderasyonu odalardan yapılır.',
                        actionLabel: 'Sesli odalar',
                        action: () => context.push('/voice-rooms'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.gavel_rounded,
                          color: AppThemeColors.liveRed,
                        ),
                        title: Text(
                          (r['activityType'] ?? 'moderasyon').toString(),
                        ),
                        subtitle: Text(
                          '${r['userName'] ?? r['username'] ?? '—'} · ${r['createdAt'] ?? ''}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
