/// canlifal.com staff rolleri — `GET /api/user/credits` → `role`.
abstract final class StaffRoles {
  static const staff = {
    'admin',
    'yonetici',
    'moderator',
    'destek',
    'yardim',
  };

  static const adminOrManager = {'admin', 'yonetici'};

  static const managerUsernames = {'admin', 'yonetici'};

  static bool isStaff(String? role) {
    if (role == null) return false;
    return staff.contains(role.toLowerCase().trim());
  }

  /// Profil yönetim paneli — yalnızca admin / yönetici (rol veya kullanıcı adı).
  static bool isAdminOrManager({String? role, String? username}) {
    final r = role?.toLowerCase().trim() ?? '';
    if (adminOrManager.contains(r)) return true;
    final u = username?.toLowerCase().trim() ?? '';
    return managerUsernames.contains(u);
  }

  static String labelTr(String role) {
    return switch (role.toLowerCase()) {
      'admin' => 'Admin',
      'yonetici' => 'Yönetici',
      'moderator' => 'Moderatör',
      'destek' => 'Destek',
      'yardim' => 'Yardım',
      _ => role,
    };
  }
}
