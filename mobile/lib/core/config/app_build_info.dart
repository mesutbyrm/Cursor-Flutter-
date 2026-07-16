/// Derleme sürümü — `pubspec.yaml` `version:` ile senkron tutun.
abstract final class AppBuildInfo {
  static const String versionName = '1.0.44';
  static const int buildNumber = 52;

  static String get full => '$versionName+$buildNumber';
}
