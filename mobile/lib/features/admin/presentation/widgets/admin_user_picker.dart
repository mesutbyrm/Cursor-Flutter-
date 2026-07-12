import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_user_search_list.dart';

/// Admin — harf yazınca anında kullanıcı listesi (modal).
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

class _AdminUserPickerSheet extends ConsumerWidget {
  const _AdminUserPickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeColors.accentPink.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Kullanıcı seç',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Expanded(
              child: AdminUserSearchList(
                autofocus: true,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                onUserSelected: (u) => Navigator.pop(context, u),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
