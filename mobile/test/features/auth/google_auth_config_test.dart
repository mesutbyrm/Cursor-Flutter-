import 'package:canlifal_social/core/config/google_auth_config.dart';
import 'package:canlifal_social/core/firebase/firebase_options_generated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleAuthConfig', () {
    test('isConfigured when firebase web client id is embedded', () {
      expect(FirebaseOptionsGenerated.googleWebClientId, isNotEmpty);
      expect(GoogleAuthConfig.isConfigured, isTrue);
    });

    test('serverClientId matches firebase_options_generated web client', () {
      expect(
        GoogleAuthConfig.serverClientId,
        FirebaseOptionsGenerated.googleWebClientId,
      );
    });

    test('createGoogleSignIn does not throw when configured', () {
      expect(() => GoogleAuthConfig.createGoogleSignIn(), returnsNormally);
    });
  });
}
