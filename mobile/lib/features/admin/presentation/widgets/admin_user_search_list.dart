import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../providers/admin_panel_providers.dart';

/// Admin kullanıcı araması — harf yazınca anında liste.
class AdminUserSearchList extends ConsumerStatefulWidget {
  const AdminUserSearchList({
    super.key,
    required this.onUserSelected,
    this.autofocus = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final ValueChanged<Map<String, dynamic>> onUserSelected;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<AdminUserSearchList> createState() =>
      _AdminUserSearchListState();
}

class _AdminUserSearchListState extends ConsumerState<AdminUserSearchList> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _label(Map<String, dynamic> u) {
    return u['username']?.toString().trim().isNotEmpty == true
        ? '@${u['username']}'
        : (u['displayName'] ?? u['name'] ?? u['id'] ?? 'Kullanıcı')
            .toString();
  }

  String? _avatar(Map<String, dynamic> u) {
    return (u['avatarUrl'] ?? u['image'] ?? u['avatar'])?.toString();
  }

  String _membershipLabel(Map<String, dynamic> u) {
    final m = (u['membership'] ?? u['membershipTier'] ?? 'basic')
        .toString()
        .toLowerCase();
    return switch (m) {
      'gold' => 'Gold',
      'premium' => 'Premium',
      'diamond' => 'Diamond',
      _ => 'Basic',
    };
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(adminUserSearchProvider);
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widget.padding,
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı — harf yazın',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        ref.read(adminUserSearchProvider.notifier).setQuery('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) {
              ref.read(adminUserSearchProvider.notifier).setQuery(v);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.when(
            loading: () => query.isEmpty
                ? _hint(context, 'Aramak için en az bir harf yazın.')
                : const Center(child: CircularProgressIndicator()),
            error: (e, _) => _hint(context, e.toString()),
            data: (rows) {
              if (query.isEmpty) {
                return _hint(context, 'Aramak için en az bir harf yazın.');
              }
              if (rows.isEmpty) {
                return _hint(context, 'Kullanıcı bulunamadı.');
              }
              return ListView.separated(
                padding: widget.padding,
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final u = rows[i];
                  final avatar = _avatar(u);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppThemeColors.accentPurple.withValues(alpha: 0.3),
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? canlifalImageProvider(avatar)
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? const Icon(Icons.person_rounded, size: 20)
                          : null,
                    ),
                    title: Text(
                      _label(u),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Jeton: ${u['coins'] ?? u['jetonBalance'] ?? '—'} · '
                      'CFC: ${u['cfcBalance'] ?? u['cfc'] ?? '—'} · '
                      _membershipLabel(u),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => widget.onUserSelected(u),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceMuted),
        ),
      ),
    );
  }
}
