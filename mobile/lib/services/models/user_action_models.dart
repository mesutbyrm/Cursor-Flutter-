/// Kullanıcı şikayet nedenleri — `POST /api/user/report`.
enum UserReportReason {
  harassment('harassment'),
  spam('spam'),
  inappropriateContent('inappropriate_content'),
  fakeAccount('fake_account'),
  scam('scam'),
  other('other');

  const UserReportReason(this.apiValue);

  final String apiValue;
}

class UserBlockResult {
  const UserBlockResult({
    required this.success,
    required this.blocked,
    this.message,
  });

  final bool success;
  final bool blocked;
  final String? message;

  factory UserBlockResult.fromJson(Map<String, dynamic> json) {
    return UserBlockResult(
      success: json['success'] == true,
      blocked: json['blocked'] == true,
      message: json['message']?.toString(),
    );
  }
}

class UserReportResult {
  const UserReportResult({
    required this.success,
    this.message,
    this.reportId,
  });

  final bool success;
  final String? message;
  final String? reportId;

  factory UserReportResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : json;
    return UserReportResult(
      success: json['success'] == true || map['success'] == true,
      message: (map['message'] ?? json['message'])?.toString(),
      reportId: (map['reportId'] ?? json['reportId'])?.toString(),
    );
  }
}

class BlockedUserEntry {
  const BlockedUserEntry({
    required this.userId,
    this.name,
    this.username,
    this.image,
    this.blockedAt,
  });

  final String userId;
  final String? name;
  final String? username;
  final String? image;
  final DateTime? blockedAt;

  factory BlockedUserEntry.fromJson(Map<String, dynamic> json) {
    return BlockedUserEntry(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      image: (json['image'] ?? json['avatar'] ?? json['avatarUrl'])?.toString(),
      blockedAt: DateTime.tryParse(json['blockedAt']?.toString() ?? ''),
    );
  }
}
