import '../../../core/util/json_util.dart';

/// Admin panelinde kullanıcı kaydından güvenilir kimlik çıkarır.
String resolveAdminUserId(Map<String, dynamic> user) {
  final direct = pick(user, [
    'id',
    'userId',
    '_id',
    'uid',
    'user_id',
    'cuid',
    'gcid',
    'realCid',
  ]);
  final s = direct?.toString().trim();
  if (s != null && s.isNotEmpty) return s;
  return '';
}

/// Arama / liste yanıtını admin formlarıyla uyumlu hale getirir.
Map<String, dynamic> normalizeAdminUserMap(Map<String, dynamic> raw) {
  final map = Map<String, dynamic>.from(raw);
  final id = resolveAdminUserId(map);
  if (id.isNotEmpty) {
    map['id'] = id;
    map['userId'] ??= id;
  }
  final username = pick(map, ['username', 'userName', 'handle'])?.toString();
  if (username != null && username.trim().isNotEmpty) {
    map['username'] = username.trim();
  }
  return map;
}

List<Map<String, dynamic>> normalizeAdminUserList(List<Map<String, dynamic>> rows) {
  return rows.map(normalizeAdminUserMap).toList(growable: false);
}
