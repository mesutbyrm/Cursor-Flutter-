import '../../../core/auth/staff_roles.dart';
import '../../admin/presentation/providers/staff_access_provider.dart';

/// GirLive Bot hitap kuralları — «Patron» yalnızca admin / yönetici (backend rolü).
abstract final class GirLivePatronAddress {
  /// Üyelik seviyesi (Gold, SVIP vb.) Patron kazandırmaz.
  static bool qualifiesForPatron({
    required StaffAccess staff,
    String? siteRole,
  }) {
    if (staff.isSiteAdmin || staff.isFounder) return true;
    return StaffRoles.isAdminOrManager(
      role: siteRole ?? staff.siteRole,
      username: staff.username,
    );
  }

  /// Bot metinlerinde kullanılacak kısa hitap (Patron veya görünen ad).
  static String salutation({
    required StaffAccess staff,
    String? siteRole,
    String? realName,
    String? username,
  }) {
    if (qualifiesForPatron(staff: staff, siteRole: siteRole)) {
      return 'Patron';
    }
    return resolveDisplayLabel(realName: realName, username: username);
  }

  static String resolveDisplayLabel({
    String? realName,
    String? username,
  }) {
    final name = realName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final u = username?.trim();
    if (u == null || u.isEmpty) return 'Misafir';
    return u.startsWith('@') ? u : '@$u';
  }
}
