import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/google_auth_config.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';
import '../../domain/entities/pf_user.dart';

class PfFirebaseAuthDatasource {
  PfFirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _googleSignInOverride = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GoogleSignIn? _googleSignInOverride;

  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ?? GoogleAuthConfig.createGoogleSignIn();
  final _uuid = const Uuid();

  bool get isAvailable => FirebaseBootstrap.isReady;

  Stream<PfUser?> watchCurrentUser() {
    if (!isAvailable) {
      return Stream.value(null);
    }
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _fetchUserDoc(user.uid) ?? _userFromFirebase(user);
    });
  }

  Future<PfUser> signInWithEmail(String email, String password) async {
    _ensureFirebase();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      return await _ensureUserDoc(user);
    } on FirebaseAuthException catch (e) {
      throw PfAuthFailure(_mapAuthError(e));
    }
  }

  Future<PfUser> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _ensureFirebase();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(displayName.trim());
      return _createUserDoc(
        cred.user!,
        displayName: displayName.trim(),
        welcomeCredits: PfConfig.welcomeCredits,
      );
    } on FirebaseAuthException catch (e) {
      throw PfAuthFailure(_mapAuthError(e));
    }
  }

  Future<PfUser> signInWithGoogle() async {
    _ensureFirebase();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const PfAuthFailure('Google girişi iptal edildi.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return _ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw PfAuthFailure(_mapAuthError(e));
    }
  }

  Future<PfUser> signInWithApple() async {
    _ensureFirebase();
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      throw const PfAuthFailure('Apple ile giriş yalnızca iOS/macOS\'ta desteklenir.');
    }
    try {
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauth);
      final name = [
        appleCred.givenName,
        appleCred.familyName,
      ].whereType<String>().join(' ').trim();
      return _ensureUserDoc(
        cred.user!,
        displayName: name.isNotEmpty ? name : null,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw PfAuthFailure(e.message);
    } on FirebaseAuthException catch (e) {
      throw PfAuthFailure(_mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<PfUser> updateProfile({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    String? zodiacSign,
  }) async {
    _ensureFirebase();
    final user = _auth.currentUser;
    if (user == null) throw const PfAuthFailure('Oturum bulunamadı.');

    final updates = <String, dynamic>{};
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      updates['displayName'] = displayName;
    }
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (birthDate != null) {
      updates['birthDate'] = Timestamp.fromDate(birthDate);
    }
    if (zodiacSign != null) updates['zodiacSign'] = zodiacSign;

    if (updates.isNotEmpty) {
      await _firestore.collection('pf_users').doc(user.uid).update(updates);
    }

    return (await _fetchUserDoc(user.uid)) ?? _userFromFirebase(user);
  }

  Future<String> uploadProfilePhoto(String userId, String localPath) async {
    _ensureFirebase();
    final ref = _storage.ref().child('pf_profiles/$userId/${_uuid.v4()}.jpg');
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _firestore.collection('pf_users').doc(uid);

  void _ensureFirebase() {
    if (!isAvailable) {
      throw const PfAuthFailure(
        'Firebase yapılandırılmamış. dart-define ile FIREBASE_PROJECT_ID ayarlayın.',
      );
    }
  }

  Future<PfUser> _ensureUserDoc(User user, {String? displayName}) async {
    final existing = await _fetchUserDoc(user.uid);
    if (existing != null) return existing;
    return _createUserDoc(
      user,
      displayName: displayName ?? user.displayName ?? 'Kullanıcı',
      welcomeCredits: PfConfig.welcomeCredits,
    );
  }

  Future<PfUser> _createUserDoc(
    User user, {
    required String displayName,
    int welcomeCredits = 0,
  }) async {
    final now = FieldValue.serverTimestamp();
    final data = {
      'email': user.email ?? '',
      'displayName': displayName,
      'photoUrl': user.photoURL,
      'credits': welcomeCredits,
      'points': 0,
      'badges': <String>[],
      'createdAt': now,
    };
    await _firestore.collection('pf_users').doc(user.uid).set(data);
    return PfUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: user.photoURL,
      credits: welcomeCredits,
      points: 0,
      badges: const [],
      createdAt: DateTime.now(),
    );
  }

  Future<PfUser?> _fetchUserDoc(String uid) async {
    final snap = await _firestore.collection('pf_users').doc(uid).get();
    if (!snap.exists) return null;
    return _userFromDoc(uid, snap.data()!);
  }

  PfUser _userFromDoc(String uid, Map<String, dynamic> data) {
    return PfUser(
      id: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Kullanıcı',
      photoUrl: data['photoUrl'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      zodiacSign: data['zodiacSign'] as String?,
      credits: (data['credits'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(data['badges'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  PfUser _userFromFirebase(User user) => PfUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Kullanıcı',
        photoUrl: user.photoURL,
      );

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'Bu e-posta ile kayıtlı hesap bulunamadı.',
      'wrong-password' => 'Şifre hatalı.',
      'email-already-in-use' => 'Bu e-posta zaten kullanılıyor.',
      'weak-password' => 'Şifre en az 6 karakter olmalı.',
      'invalid-email' => 'Geçersiz e-posta adresi.',
      'user-disabled' => 'Hesabınız devre dışı bırakılmış.',
      _ => e.message ?? 'Kimlik doğrulama hatası.',
    };
  }
}
