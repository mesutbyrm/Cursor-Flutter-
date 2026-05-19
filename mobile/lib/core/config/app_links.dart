/// Sabit dağıtım ve yardımcı bağlantılar (CI: `apk-latest` sürümü).
abstract final class AppLinks {
  AppLinks._();

  /// GitHub Releases — `main` üzerindeki son başarılı [Build release APK] çıktısı.
  static const String androidTestApk =
      'https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk';

  static const String buildApkWorkflow =
      'https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml';
}
