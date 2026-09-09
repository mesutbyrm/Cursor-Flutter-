import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/admin_user_permissions.dart';
import '../providers/staff_access_provider.dart';

/// Faz 4 — salt okunur rol × sekme matrisi (site ayarı API gelene kadar).
class AdminRolePermissionsMatrix extends StatelessWidget {
  const AdminRolePermissionsMatrix({super.key});

  static final _roles = [
    ('Kurucu', _founder),
    ('Site admin', _siteAdmin),
    ('Ödeme yön.', _payment),
    ('Moderatör', _moderator),
    ('Destek', _support),
  ];

  static final _rows = <(String, bool Function(StaffAccess))>[
    ('Özet', AdminUserPermissions.canViewOverview),
    ('Finans', AdminUserPermissions.canViewFinance),
    ('Finans düzenle', AdminUserPermissions.canEditFinance),
    ('Hediyeler', AdminUserPermissions.canViewGifts),
    ('Yayın/Oda', AdminUserPermissions.canViewBroadcasts),
    ('Aktivite', AdminUserPermissions.canViewActivity),
    ('Profil düzenle', AdminUserPermissions.canEditProfile),
    ('Admin atama', AdminUserPermissions.canAssignAdminRole),
    ('Moderatör atama', AdminUserPermissions.canAssignStaffRole),
    ('Ban', AdminUserPermissions.canBanUser),
    ('Falcı onayı', AdminUserPermissions.canManagePsychic),
    ('Özellik bayrakları', AdminUserPermissions.canManageFeatureFlags),
    ('Adına oda', AdminUserPermissions.canImpersonateRoomCreate),
    ('PK ban', AdminUserPermissions.canManagePkBan),
    ('Animasyon ata', AdminUserPermissions.canAssignSiteAnimation),
    ('Ödeme onayı', AdminUserPermissions.canReviewUserPayments),
    ('Çekim limiti', AdminUserPermissions.canSetWithdrawalLimit),
    ('Kullanıcı sil', AdminUserPermissions.canDeleteUser),
  ];

  static StaffAccess _founder = const StaffAccess(
    canManagePayments: true,
    isSiteAdmin: true,
    showAdminPanel: true,
    canManageGifts: true,
    canManageSiteAnimations: true,
    isStaffMember: true,
    canModerate: true,
    canManageVoiceRooms: true,
    canManageLiveStreams: true,
    canManageUsers: true,
    canViewReports: true,
    canManageNotifications: true,
    isSupportStaff: false,
    isFounder: true,
  );

  static StaffAccess _siteAdmin = const StaffAccess(
    canManagePayments: true,
    isSiteAdmin: true,
    showAdminPanel: true,
    canManageGifts: true,
    canManageSiteAnimations: true,
    isStaffMember: true,
    canModerate: true,
    canManageVoiceRooms: true,
    canManageLiveStreams: true,
    canManageUsers: true,
    canViewReports: true,
    canManageNotifications: true,
    isSupportStaff: false,
  );

  static StaffAccess _payment = const StaffAccess(
    canManagePayments: true,
    isSiteAdmin: false,
    showAdminPanel: true,
    canManageGifts: false,
    canManageSiteAnimations: false,
    isStaffMember: true,
    canModerate: false,
    canManageVoiceRooms: false,
    canManageLiveStreams: false,
    canManageUsers: true,
    canViewReports: true,
    canManageNotifications: true,
    isSupportStaff: false,
  );

  static StaffAccess _moderator = const StaffAccess(
    canManagePayments: false,
    isSiteAdmin: false,
    showAdminPanel: false,
    canManageGifts: false,
    canManageSiteAnimations: false,
    isStaffMember: true,
    canModerate: true,
    canManageVoiceRooms: true,
    canManageLiveStreams: true,
    canManageUsers: false,
    canViewReports: true,
    canManageNotifications: false,
    isSupportStaff: false,
  );

  static StaffAccess _support = const StaffAccess(
    canManagePayments: false,
    isSiteAdmin: false,
    showAdminPanel: false,
    canManageGifts: false,
    canManageSiteAnimations: false,
    isStaffMember: true,
    canModerate: false,
    canManageVoiceRooms: false,
    canManageLiveStreams: false,
    canManageUsers: false,
    canViewReports: false,
    canManageNotifications: false,
    isSupportStaff: true,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rol yetki matrisi (salt okunur)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Gelecek: GET/PUT /api/admin/role-permissions ile site ayarından düzenlenecek.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columnSpacing: 12,
            columns: [
              const DataColumn(label: Text('Eylem', style: TextStyle(fontSize: 11))),
              for (final r in _roles)
                DataColumn(
                  label: Text(r.$1, style: const TextStyle(fontSize: 10)),
                ),
            ],
            rows: [
              for (final row in _rows)
                DataRow(
                  cells: [
                    DataCell(Text(row.$1, style: const TextStyle(fontSize: 11))),
                    for (final role in _roles)
                      DataCell(_cell(row.$2(role.$2))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(bool allowed) {
    return Icon(
      allowed ? Icons.check_circle : Icons.remove_circle_outline,
      size: 16,
      color: allowed ? AppThemeColors.accentCyan : Colors.white24,
    );
  }
}
