import '../../../core/util/json_util.dart';

/// `GET /api/me/permissions` — canlifal PR #39/#40.
class MePermissions {
  const MePermissions({
    this.role = 'user',
    this.isSuper = false,
    this.permissions = const {},
    this.groups = const {},
  });

  final String role;
  final bool isSuper;
  final Set<String> permissions;
  final Map<String, List<String>> groups;

  bool can(String permission) =>
      isSuper || permissions.contains(permission);

  factory MePermissions.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? asJsonMap(json['data'])
        : asJsonMap(json);
    final permsRaw = data['permissions'];
    final groupsRaw = data['groups'];
    final groups = <String, List<String>>{};
    if (groupsRaw is Map) {
      for (final e in groupsRaw.entries) {
        final list = e.value;
        if (list is List) {
          groups[e.key.toString()] =
              list.map((x) => x.toString()).toList(growable: false);
        }
      }
    }
    return MePermissions(
      role: data['role']?.toString() ?? 'user',
      isSuper: data['isSuper'] == true,
      permissions: permsRaw is List
          ? permsRaw.map((e) => e.toString()).toSet()
          : const {},
      groups: groups,
    );
  }
}
