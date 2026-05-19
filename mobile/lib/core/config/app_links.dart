/// Sabit dağıtım ve yardımcı bağlantılar (CI: `apk-latest` sürümü).
abstract final class AppLinks {
  AppLinks._();

  /// GitHub Releases — `main` üzerindeki son başarılı [Build release APK] çıktısı.
  static const String androidTestApk =
      'https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk';

  /// Aynı APK; Chrome Android’de doğrudan indirme bazen %100’de takılır — Assets’ten
  /// indirmek veya Firefox / Samsung Internet denemek için sürüm sayfası.
  static const String androidTestApkReleaseTagPage =
      'https://github.com/mesutbyrm/Cursor-Flutter-/releases/tag/apk-latest';

  static const String buildApkWorkflow =
      'https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml';
}
