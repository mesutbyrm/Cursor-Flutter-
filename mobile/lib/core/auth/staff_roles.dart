abstract final class StaffRoles {
  static const staff = {
    'admin',
    'yonetici',
    'moderator',
    'destek',
    'yardim',
  };

  static bool isStaff(String? role) {
    if (role == null) return false;
    return staff.contains(role.toLowerCase().trim());
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
