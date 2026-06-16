import 'package:shared_preferences/shared_preferences.dart';

/// Son seçilen jeton paketi ve ödeme yöntemi (cihazda).
class JetonPurchasePrefs {
  static const _packageKey = 'jeton_last_package_id_v1';
  static const _methodKey = 'jeton_last_payment_method_v1';

  Future<String?> loadLastPackageId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_packageKey)?.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  Future<void> saveLastPackageId(String packageId) async {
    final id = packageId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_packageKey, id);
  }

  Future<String?> loadLastPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString(_methodKey)?.trim();
    return m != null && m.isNotEmpty ? m : null;
  }

  Future<void> saveLastPaymentMethod(String method) async {
    final m = method.trim();
    if (m.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_methodKey, m);
  }
}
