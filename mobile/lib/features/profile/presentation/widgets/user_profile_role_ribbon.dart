import 'package:flutter/material.dart';

import '../../../../core/auth/staff_roles.dart';

/// Kurucu / Admin profillerinde ad altında gösterilen onur şeridi.
/// Kurucu > Admin önceliği; ikisi de değilse görünmez.
class UserProfileRoleRibbon extends StatelessWidget {
  const UserProfileRoleRibbon({
    super.key,
    required this.role,
    required this.username,
  });

  final String? role;
  final String username;

  @override
  Widget build(BuildContext context) {
    final isFounder = StaffRoles.isFounderUser(role: role, username: username);
    final isAdmin =
        !isFounder && StaffRoles.isSiteAdminUser(role: role, username: username);
    if (!isFounder && !isAdmin) return const SizedBox.shrink();

    final label = isFounder ? 'KURUCU' : 'ADMİN';
    final icon = isFounder
        ? Icons.emoji_events_rounded
        : Icons.verified_user_rounded;
    final colors = isFounder
        ? const [Color(0xFFFFD54F), Color(0xFFFF8A00)]
        : const [Color(0xFF8B5CF6), Color(0xFF6366F1)];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
