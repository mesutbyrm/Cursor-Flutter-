/// Giriş / kayıt — global overlay ve davet host'u bu rotalarda devre dışı.
abstract final class AuthRoutePaths {
  static const publicPaths = {
    '/login',
    '/register',
    '/splash',
    '/auth/forgot-password',
    '/auth/otp-verify',
  };

  static bool isPublicAuthPath(String path) => publicPaths.contains(path);
}
