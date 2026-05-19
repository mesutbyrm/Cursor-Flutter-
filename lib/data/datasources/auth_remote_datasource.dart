import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/api_paths.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../domain/entities/entities.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await _firebaseSignIn(email: email, password: password);
    final Map<String, dynamic> data = await _apiClient.postJson(
      ApiPaths.login,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    await _persistTokens(data);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _firebaseRegister(email: email, password: password);
    final Map<String, dynamic> data = await _apiClient.postJson(
      ApiPaths.register,
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
    await _persistTokens(data);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<void> resetPassword(String email) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: email,
        );
      }
      await _apiClient.postJson(
        ApiPaths.forgotPassword,
        body: <String, dynamic>{'email': email},
      );
    } on Object {
      return;
    }
  }

  Future<void> signOut() async {
    try {
      final String? refresh = await _tokenStorage.readRefreshToken();
      if (refresh != null) {
        await _apiClient.postJson(
          ApiPaths.logout,
          body: <String, dynamic>{'refreshToken': refresh},
        );
      }
    } on Object {
      // Sunucu çıkışı başarısız olsa da yerel oturumu temizle.
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signOut();
      }
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<AppUser?> restoreSession() async {
    final String? token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(ApiPaths.me);
      return AppUser.fromJson(data);
    } on AppException {
      await _tokenStorage.clear();
      return null;
    } on Object {
      return null;
    }
  }

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final String? accessToken = data['accessToken'] as String?;
    final String? refreshToken = data['refreshToken'] as String?;
    if (accessToken != null && refreshToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  Future<void> _firebaseSignIn({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _firebaseRegister({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
