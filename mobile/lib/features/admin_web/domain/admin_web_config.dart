import '../../../core/config/env.dart';

/// Mobil admin WebView yapılandırması.
abstract final class AdminWebConfig {
  static String get origin => Env.webOrigin;

  static String get adminPath => '/admin';

  static Uri get adminUri => Uri.parse('$origin$adminPath');

  /// Mobil istemci bayrağı — sunucu middleware için.
  static const mobileClientQuery = 'canlifal_mobile=1';

  /// Yalnız `/admin` altındaki web sayfaları açılabilir (ör. `/admin/withdrawals`).
  static String safeAdminPath(String? path) {
    final p = (path ?? '').trim();
    if (p == adminPath || p.startsWith('$adminPath/')) {
      if (!p.contains('..') && !p.contains('//')) return p;
    }
    return adminPath;
  }

  static Uri adminEntryUri({String? accessToken, String? path}) {
    final base = Uri.parse('$origin${safeAdminPath(path)}?$mobileClientQuery');
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
