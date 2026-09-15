import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../providers/admin_user_hub_providers.dart';

/// Admin özet — kullanıcı durum rozetleri (§38).
class AdminUserPresenceStrip extends ConsumerWidget {
  const AdminUserPresenceStrip({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminUserOverviewProvider(userId));
    return overview.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final presence = data['presence'];
        if (presence is! Map) return const SizedBox.shrink();
        final labels = presence['labels'];
        if (labels is! List || labels.isEmpty) {
          final online = pick(presence, ['online']) == true;
          if (!online) return const SizedBox.shrink();
          return _chip('🟢 Online');
        }
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: labels
              .map((e) => _chip(e.toString()))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _chip(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
