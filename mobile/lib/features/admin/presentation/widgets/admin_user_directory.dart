import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../domain/admin_user_util.dart';
import '../providers/admin_panel_providers.dart';

/// Kullanıcı dizini filtresi → sunucu parametreleri (`GET /api/admin/users`).
enum AdminUserFilter {
  all('Tümü', segment: 'all'),
  active('Aktif', segment: 'active'),
  passive('Pasif', segment: 'passive'),
  banned('Banlı', segment: 'all', clientBanned: true),
  broadcaster('Yayıncı', segment: 'all', adv: 'broadcasting'),
  admin('Admin', segment: 'all', role: 'admin');

  const AdminUserFilter(
    this.label, {
    required this.segment,
    this.adv = '',
    this.role = '',
    this.clientBanned = false,
  });

  final String label;
  final String segment;
  final String adv;
  final String role;

  /// Sunucuda «banlı» filtresi yok; liste istemcide `isBanned/banned/isFrozen`
  /// alanlarına göre süzülür (yalnızca yüklenen kayıtlar içinde).
  final bool clientBanned;
}

bool adminUserIsBanned(Map<String, dynamic> u) =>
    u['isBanned'] == true || u['banned'] == true || u['isFrozen'] == true;

bool adminUserIsOnline(Map<String, dynamic> u) {
  final raw = u['lastActiveAt']?.toString();
  final t = raw == null ? null : DateTime.tryParse(raw);
  return t != null && DateTime.now().difference(t.toLocal()).inMinutes < 5;
}

/// Admin kullanıcı yönetimi: arama + filtre çipleri + sayfalı liste + işlem menüsü.
/// Yeni uç eklenmez; ban/mute/rol işlemleri mevcut komuta merkezi ekranındadır.
class AdminUserDirectory extends ConsumerStatefulWidget {
  const AdminUserDirectory({super.key});

  @override
  ConsumerState<AdminUserDirectory> createState() => _AdminUserDirectoryState();
}

class _AdminUserDirectoryState extends ConsumerState<AdminUserDirectory> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  var _filter = AdminUserFilter.all;
  var _items = <Map<String, dynamic>>[];
  var _page = 1;
  var _totalPages = 1;
  var _loading = true;
  var _loadingMore = false;
  String? _error;
  var _seq = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) unawaited(_loadMore());
    });
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    final seq = ++_seq;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final res = await ref.read(adminRemoteProvider).fetchUsersPage(
            search: _search.text,
            segment: _filter.segment,
            role: _filter.role,
            adv: _filter.adv,
            page: reset ? 1 : _page + 1,
          );
      if (!mounted || seq != _seq) return;
      setState(() {
        _items = reset ? res.users : [..._items, ...res.users];
        _page = reset ? 1 : _page + 1;
        _totalPages = res.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = ApiException.userMessage(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    await _load(reset: false);
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
    setState(() {});
  }

  void _setFilter(AdminUserFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    unawaited(_load(reset: true));
  }

  List<Map<String, dynamic>> get _visible => _filter.clientBanned
      ? _items.where(adminUserIsBanned).toList(growable: false)
      : _items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 0),
          child: TextField(
            controller: _search,
            onChanged: _onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara…',
              isDense: true,
              filled: true,
              fillColor: mockCardColor(context),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _search.clear();
                        _onQuery('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mockCardBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mockCardBorder(context)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 0),
            itemCount: AdminUserFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = AdminUserFilter.values[i];
              final selected = _filter == f;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _setFilter(f),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected
                        ? const Color(0xFF7C5CFF)
                        : mockCardColor(context),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF9B83FF)
                          : mockCardBorder(context),
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : c.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_filter.clientBanned)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(
              'Banlı filtresi yüklenen kayıtlar içinde uygulanır; sunucu '
              'henüz ban durumuna göre süzme sunmuyor.',
              style: TextStyle(fontSize: 11.5, color: c.onSurfaceMuted),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: _body(context, rows)),
      ],
    );
  }

  Widget _body(BuildContext context, List<Map<String, dynamic>> rows) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _load(reset: true),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'Kullanıcı bulunamadı.',
          style: TextStyle(color: context.colors.onSurfaceMuted),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 32),
        itemCount: rows.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          if (i >= rows.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return AdminUserRow(
            user: rows[i],
            onChanged: () => _load(reset: true),
          );
        },
      ),
    );
  }
}

/// Kullanıcı satırı: avatar, ad + @kullanıcı adı, rol rozeti, durum, işlem menüsü.
class AdminUserRow extends StatelessWidget {
  const AdminUserRow({super.key, required this.user, this.onChanged});

  final Map<String, dynamic> user;
  final VoidCallback? onChanged;

  String get _username => user['username']?.toString().trim() ?? '';

  String get _display {
    final n = (user['name'] ?? user['displayName'])?.toString().trim() ?? '';
    if (n.isNotEmpty) return n;
    return _username.isNotEmpty ? _username : 'Kullanıcı';
  }

  static String roleLabel(String role) => switch (role.toLowerCase()) {
        'user' => 'Kullanıcı',
        'admin' => 'Admin',
        'moderator' => 'Moderatör',
        'broadcaster' || 'streamer' => 'Yayıncı',
        _ => role,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final avatar = (user['image'] ?? user['avatarUrl'] ?? user['avatar'])?.toString();
    final role = (user['role'] ?? 'user').toString();
    final membership = (user['membership'] ?? 'basic').toString().toLowerCase();
    final isVip = const {'gold', 'premium', 'diamond', 'svip'}.contains(membership);
    final online = adminUserIsOnline(user);
    final banned = adminUserIsBanned(user);
    final id = resolveAdminUserId(user);
    final statusText = banned ? 'Banlı' : (online ? 'Aktif' : 'Pasif');
    final statusColor = (banned || !online)
        ? const Color(0xFFFF4D5E)
        : const Color(0xFF2ECC71);

    Widget pill(String text, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color.lerp(color, Colors.white, 0.35),
            ),
          ),
        );

    return Material(
      color: mockCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: mockCardBorder(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id.isEmpty ? null : () => _open(context, id),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 2, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: c.primary.withValues(alpha: 0.2),
                backgroundImage: (avatar != null && avatar.startsWith('http'))
                    ? canlifalImageProvider(avatar)
                    : null,
                child: (avatar == null || !avatar.startsWith('http'))
                    ? const Icon(Icons.person_rounded)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: c.onSurface,
                      ),
                    ),
                    if (_username.isNotEmpty)
                      Text(
                        '@$_username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    alignment: WrapAlignment.end,
                    children: [
                      if (isVip) pill('VIP', const Color(0xFF8B5CF6)),
                      pill(roleLabel(role), const Color(0xFF7C5CFF)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'İşlemler',
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (v) => _onAction(context, id, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('Profil')),
                  PopupMenuItem(value: 'ban', child: Text('Ban / Unban')),
                  PopupMenuItem(value: 'mute', child: Text('Mute')),
                  PopupMenuItem(value: 'role', child: Text('Rol')),
                  PopupMenuItem(value: 'reports', child: Text('Şikâyetler')),
                  PopupMenuItem(value: 'activity', child: Text('Aktiviteler')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String id) async {
    await context.push('/admin/users/$id');
    onChanged?.call();
  }

  Future<void> _onAction(BuildContext context, String id, String action) async {
    if (id.isEmpty) return;
    switch (action) {
      case 'reports':
        await context.push('/admin/reports');
      case 'activity':
        await context.push('/admin/activity-log');
      default:
        // Profil / Ban / Mute / Rol: komuta merkezi ekranında (yetki kontrollü).
        await _open(context, id);
    }
  }
}
