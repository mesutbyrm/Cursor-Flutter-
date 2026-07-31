import 'auth_user.dart';

/// Tüm auth uçları için ortak yanıt: login, register, google, tiktok, refresh.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.isNewUser,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final bool? isNewUser;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    if (userRaw is! Map) {
      throw const FormatException('Auth yanıtında user alanı eksik');
    }
    return AuthResponse(
      accessToken: _requireToken(json, 'accessToken', 'access_token'),
      refreshToken: _requireToken(json, 'refreshToken', 'refresh_token'),
      isNewUser: json['isNewUser'] == true,
      user: AuthUser.fromJson(
        userRaw is Map<String, dynamic>
            ? userRaw
            : Map<String, dynamic>.from(userRaw),
      ),
    );
  }

  static String _requireToken(
    Map<String, dynamic> json,
    String primary,
    String alt,
  ) {
    final v = json[primary] ?? json[alt];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('Auth yanıtında $primary eksik');
  }

  /// `POST /api/auth/mobile-refresh` — yalnızca token çifti (user yok).
  static ({String accessToken, String refreshToken})? parseRefreshTokens(
    Map<String, dynamic>? body,
  ) {
    if (body == null || body.isEmpty) return null;
    var map = body;
    if (body['success'] == true && body['data'] is Map) {
      map = Map<String, dynamic>.from(body['data'] as Map);
    } else if (body['data'] is Map) {
      map = Map<String, dynamic>.from(body['data'] as Map);
    }
    final access = map['accessToken'] ?? map['access_token'];
    final refresh = map['refreshToken'] ?? map['refresh_token'];
    if (access is String &&
        access.isNotEmpty &&
        refresh is String &&
        refresh.isNotEmpty) {
      return (accessToken: access, refreshToken: refresh);
    }
    return null;
  }

  /// `{ success: true, data: { ... } }` veya düz JSON.
  static AuthResponse parseRoot(Map<String, dynamic>? body) {
    if (body == null || body.isEmpty) {
      throw const FormatException('Boş auth yanıtı');
    }
    if (body['success'] == true && body['data'] is Map) {
      return AuthResponse.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    final data = body['data'];
    if (data is Map) {
      return AuthResponse.fromJson(Map<String, dynamic>.from(data));
    }
    return AuthResponse.fromJson(body);
  }
}
