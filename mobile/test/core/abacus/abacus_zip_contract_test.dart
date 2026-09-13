import 'package:canlifal_social/core/abacus/abacus_fortune_ready_paths.dart';
import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Abacus zip §1 auth paths', () {
    test('canonical', () {
      expect(
        ApiEndpoints.authEmailSendVerification,
        '/api/auth/email/send-verification',
      );
      expect(ApiEndpoints.authPhoneSendOtp, '/api/auth/phone/send-otp');
      expect(ApiEndpoints.authPhoneVerifyOtp, '/api/auth/phone/verify-otp');
      expect(ApiEndpoints.authVerification, '/api/verification');
    });
  });

  group('Abacus zip §2 me / user', () {
    test('membership and social settings', () {
      expect(ApiEndpoints.meMembership, '/api/me/membership');
      expect(ApiEndpoints.userSocialSettings, '/api/user/social-settings');
      expect(
        ApiEndpoints.meProfileVisitorsCanonical,
        '/api/me/profile-visitors',
      );
    });
  });

  group('Abacus zip §4 dreams', () {
    test('contest and interpret paths', () {
      expect(ApiEndpoints.dreamContest, '/api/dream-contest');
      expect(
        ApiEndpoints.dreamContestEntries('c1'),
        '/api/dream-contest/c1/entries',
      );
      expect(ApiEndpoints.dreamsInterpret, '/api/dreams/interpret');
    });
  });

  group('Abacus zip §11 social extras', () {
    test('hashtags teams share', () {
      expect(ApiEndpoints.socialProfile, '/api/social/profile');
      expect(ApiEndpoints.shareCard, '/api/share-card');
      expect(ApiEndpoints.teams, '/api/teams');
      expect(ApiEndpoints.hashtagsTrending, '/api/hashtags/trending');
    });
  });

  test('§3 fortune FLUTTER_READY slug list matches fortuneReading', () {
    for (final path in AbacusFortuneReadyPaths.all) {
      final slug = path.split('/').last;
      expect(ApiEndpoints.fortuneReading(slug), path);
    }
  });
}
