import '../../../core/config/env.dart';

/// Mobil admin WebView yapılandırması.
abstract final class AdminWebConfig {
  static String get origin => Env.webOrigin;

  static String get adminPath => '/admin';

  static Uri get adminUri => Uri.parse('$origin$adminPath');

  /// Mobil istemci bayrağı — sunucu middleware için.
  static const mobileClientQuery = 'canlifal_mobile=1';

  static Uri adminEntryUri({String? accessToken}) {
    final base = Uri.parse('$origin$adminPath?$mobileClientQuery');
    if (accessToken == null || accessToken.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        'mobile_token': accessToken,
      },
    );
  }

  static bool isLoginPath(Uri uri) {
    final p = uri.path.toLowerCase();
    return p == '/giris' ||
        p == '/login' ||
        p.contains('/auth/signin') ||
        p.contains('/auth/login');
  }

  static bool isAllowedNavigation(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host == 'canlifal.com' || host.endsWith('.canlifal.com')) {
      return true;
    }
    if (host == 'canlifalapi.abacusai.app' ||
        host.endsWith('.abacusai.app')) {
      return true;
    }
    return false;
  }
}
