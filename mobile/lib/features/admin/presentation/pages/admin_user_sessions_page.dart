import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Admin — Aktif kullanıcı oturumları yönetimi.
class AdminUserSessionsPage extends ConsumerStatefulWidget {
  const AdminUserSessionsPage({super.key});

  @override
  ConsumerState<AdminUserSessionsPage> createState() => _AdminUserSessionsPageState();
}

class _AdminUserSessionsPageState extends ConsumerState<AdminUserSessionsPage> {
  Future<List<Map<String, dynamic>>>? _future;
  String? _filterDevice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _future = _load());
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    // Mock data — API yazılana kadar
    return [
      {
        'sessionId': 'sess_001',
        'username': 'psychic_user_1',
        'userId': 'user_001',
        'device': 'Mobile',
        'os': 'Android',
        'loginTime': DateTime.now().subtract(const Duration(hours: 2)),
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 5)),
        'ipAddress': '192.168.1.100',
        'location': 'İstanbul, TR',
      },
      {
        'sessionId': 'sess_002',
        'username': 'normal_user_1',
        'userId': 'user_002',
        'device': 'Web',
        'os': 'Windows',
        'loginTime': DateTime.now().subtract(const Duration(hours: 8)),
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 30)),
        'ipAddress': '192.168.1.101',
        'location': 'Ankara, TR',
      },
      {
        'sessionId': 'sess_003',
        'username': 'streamer_user_1',
        'userId': 'user_003',
        'device': 'Mobile',
        'os': 'iOS',
        'loginTime': DateTime.now().subtract(const Duration(hours: 1)),
        'lastActivity': DateTime.now().subtract(const Duration(seconds: 30)),
        'ipAddress': '192.168.1.102',
        'location': 'İzmir, TR',
      },
      {
        'sessionId': 'sess_004',
        'username': 'admin_user_1',
        'userId': 'admin_001',
        'device': 'Web',
        'os': 'macOS',
        'loginTime': DateTime.now().subtract(const Duration(days: 1)),
        'lastActivity': DateTime.now().subtract(const Duration(hours: 1)),
        'ipAddress': '192.168.1.103',
        'location': 'Londra, UK',
      },
    ];
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageUsers && !access.canManagePayments) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Oturum yönetimi yalnızca yöneticiler tarafından erişilir.',
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
                      title: 'Aktif Oturumlar',
                      subtitle: 'Cihaz ve oturum yönetimi',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            // Filtreler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: _filterDevice == null,
                      onSelected: (_) => setState(() => _filterDevice = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Mobile'),
                      selected: _filterDevice == 'Mobile',
                      onSelected: (_) => setState(() => _filterDevice = 'Mobile'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Web'),
                      selected: _filterDevice == 'Web',
                      onSelected: (_) => setState(() => _filterDevice = 'Web'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (_future == null || snap.connectionState == ConnectionState.waiting) {
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
                        icon: Icons.devices_rounded,
                        message: 'Aktif oturum bulunamadı.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async => _refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final session = rows[i];
                        return _SessionCard(session: session);
                      },
                    ),
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final Map<String, dynamic> session;

  IconData _getDeviceIcon(String device) {
    if (device == 'Mobile') return Icons.smartphone_rounded;
    if (device == 'Web') return Icons.computer_rounded;
    if (device == 'Tablet') return Icons.tablet_rounded;
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final username = session['username']?.toString() ?? '—';
    final device = session['device']?.toString() ?? '—';
    final os = session['os']?.toString() ?? '—';
    final loginTime = session['loginTime'] as DateTime?;
    final lastActivity = session['lastActivity'] as DateTime?;
    final location = session['location']?.toString() ?? '—';

    final isActive = lastActivity != null && DateTime.now().difference(lastActivity).inMinutes < 15;

    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDeviceIcon(device),
                color: AppThemeColors.accentCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$device · $os',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Aktif' : 'Hareketsiz',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.ip, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                session['ipAddress']?.toString() ?? '—',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Giriş: ${loginTime != null ? DateFormat('dd.MM.yyyy HH:mm').format(loginTime.toLocal()) : '—'}',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
