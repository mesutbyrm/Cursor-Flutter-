import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../admin/presentation/providers/staff_access_provider.dart';

/// Admin/yetkili profilinde belirgin "YÖNETİM MERKEZİ" düğmesi.
/// Yetkisiz kullanıcıda hiç çizilmez.
class ProfileManagementCenterButton extends ConsumerWidget {
  const ProfileManagementCenterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canAccessAdminHome) return const SizedBox.shrink();
    const gold = Color(0xFFFFC13B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/admin/center'),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD36B), Color(0xFFFF9F1C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2B1B00)),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'YÖNETİM MERKEZİ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF2B1B00),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
