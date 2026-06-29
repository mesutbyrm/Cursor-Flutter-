import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../providers/admin_panel_providers.dart';

/// Admin — harf yazınca anında kullanıcı listesi.
class AdminUserPicker {
  AdminUserPicker._();

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminUserPickerSheet(ref: ref),
    );
  }
}

class _AdminUserPickerSheet extends ConsumerStatefulWidget {
  const _AdminUserPickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_AdminUserPickerSheet> createState() =>
      _AdminUserPickerSheetState();
}

class _AdminUserPickerSheetState extends ConsumerState<_AdminUserPickerSheet> {
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

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(adminUserSearchProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeColors.accentPink.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kullanıcı seç',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı — harf yazın',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                ref.read(adminUserSearchProvider.notifier).setQuery(v);
              },
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: results.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    e.toString(),
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                ),
                data: (rows) {
                  if (_controller.text.trim().isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aramak için en az bir harf yazın.',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    );
                  }
                  if (rows.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kullanıcı bulunamadı.',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
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
                          'CFC: ${u['cfcBalance'] ?? u['cfc'] ?? '—'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceMuted,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, u),
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
