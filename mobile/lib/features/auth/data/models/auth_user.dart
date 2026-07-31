import '../../core/util/json_util.dart';

/// Login / register / refresh yanıtındaki `user` nesnesi.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    this.role = 'user',
    this.image,
    this.credits = 0,
    this.jetonBalance = 0,
    this.cfcBalance = 0,
    this.membership = 'free',
    this.membershipExpiresAt,
    this.preferredLanguage = 'tr',
    this.level = 1,
    this.bio,
    this.phone,
    this.birthDate,
    this.zodiacSign,
    this.referralCode,
  });

  final String id;
  final String email;
  final String name;
  final String? username;
  final String role;
  final String? image;
  final int credits;
  final int jetonBalance;
  final int cfcBalance;
  final String? membership;
  final DateTime? membershipExpiresAt;
  final String preferredLanguage;
  final int level;
  final String? bio;
  final String? phone;
  final DateTime? birthDate;
  final String? zodiacSign;
  final String? referralCode;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: pick(json, ['id', 'userId', '_id'])?.toString() ?? '',
      email: pick(json, ['email'])?.toString() ?? '',
      name: pick(json, ['name', 'displayName', 'display_name'])?.toString() ?? '',
      username: pick(json, ['username', 'userName', 'handle'])?.toString(),
      role: pick(json, ['role', 'tier'])?.toString() ?? 'user',
      image: pick(json, ['image', 'avatar', 'avatarUrl', 'photoUrl'])?.toString(),
      credits: asInt(pick(json, ['credits'])),
      jetonBalance: asInt(pick(json, ['jetonBalance', 'coinBalance', 'coins'])),
      cfcBalance: asInt(pick(json, ['cfcBalance'])),
      membership: pick(json, ['membership'])?.toString(),
      membershipExpiresAt: DateTime.tryParse(
        pick(json, ['membershipExpiresAt'])?.toString() ?? '',
      ),
      preferredLanguage:
          pick(json, ['preferredLanguage', 'language'])?.toString() ?? 'tr',
      level: () {
        final n = asInt(pick(json, ['level']));
        return n > 0 ? n : 1;
      }(),
      bio: pick(json, ['bio'])?.toString(),
      phone: pick(json, ['phone'])?.toString(),
      birthDate: DateTime.tryParse(
        pick(json, ['birthDate', 'birth_date'])?.toString() ?? '',
      ),
      zodiacSign: pick(json, ['zodiacSign', 'zodiac_sign'])?.toString(),
      referralCode: pick(json, ['referralCode', 'referral_code'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (username != null) 'username': username,
        'role': role,
        if (image != null) 'image': image,
        'credits': credits,
        'jetonBalance': jetonBalance,
        'cfcBalance': cfcBalance,
        if (membership != null) 'membership': membership,
        if (membershipExpiresAt != null)
          'membershipExpiresAt': membershipExpiresAt!.toIso8601String(),
        'preferredLanguage': preferredLanguage,
        'level': level,
        if (bio != null) 'bio': bio,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        if (zodiacSign != null) 'zodiacSign': zodiacSign,
        if (referralCode != null) 'referralCode': referralCode,
      };
}
