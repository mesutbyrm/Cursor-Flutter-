/// canlifal.com staff rolleri — `GET /api/user/credits` → `role`.
abstract final class StaffRoles {
  static const staff = {
    'admin',
    'yonetici',
    'moderator',
    'destek',
    'yardim',
    'super_admin',
    'superadmin',
    'founder',
  };

  static const adminOrManager = {
    'admin',
    'yonetici',
    'super_admin',
    'superadmin',
    'founder',
  };

  static const managerUsernames = {'admin', 'yonetici'};

  /// Site yöneticisi kullanıcı adı (`admin` — IRC staff moderatörü değil).
  /// Tam yetkili hesaplar — admin + kurucu (yonetici).
  static const siteAdminUsernames = managerUsernames;

  /// Admin paneli, hediye CRUD, sesli oda bypass — admin ve yönetici.
  static bool isSiteAdminUser({String? role, String? username}) {
    if (isAdminOrManager(role: role, username: username)) return true;
    final r = role?.toLowerCase().trim() ?? '';
    return r == 'super_admin' || r == 'superadmin' || r == 'founder';
  }

  /// Tüm yönetim işlemleri (jeton, CFC, üyelik, hediye, oda).
  static bool hasFullStaffAccess({String? role, String? username, bool? walletIsAdmin}) {
    if (walletIsAdmin == true) return true;
    return isSiteAdminUser(role: role, username: username);
  }

  /// Profil admin paneli — site admin veya ödeme yöneticisi.
  static bool canAccessAdminPanel({
    String? role,
    String? username,
    bool? walletIsAdmin,
  }) {
    if (walletIsAdmin == true) return true;
    if (isSiteAdminUser(role: role, username: username)) return true;
    return isAdminOrManager(role: role, username: username);
  }

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
      'admin' => 'Site Admin',
      'yonetici' => 'Kurucu',
      'moderator' => 'Moderatör',
      'destek' => 'Destek',
      'yardim' => 'Yardım',
      'super_admin' => 'Süper Admin',
      'superadmin' => 'Süper Admin',
      'founder' => 'Kurucu',
      _ => role,
    };
  }
}
