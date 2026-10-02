/// VIP şifreli oda erişimi — sunucu yanıt modelleri.
///
/// Gerçek şifre hiçbir zaman istemciye gelmez; yalnızca sunucunun verdiği
/// kısa ömürlü imzalı [accessToken] saklanır.

/// `GET verify-password` — modal açılırken durum.
class RoomAccessStatus {
  const RoomAccessStatus({
    required this.passwordProtected,
    this.maxAttempts = 3,
    this.remainingAttempts = 3,
    this.locked = false,
    this.bypass = false,
    this.joinRequestStatus,
  });

  final bool passwordProtected;
  final int maxAttempts;
  final int remainingAttempts;
  final bool locked;

  /// Oda sahibi / yönetici: şifre sorulmaz.
  final bool bypass;

  /// `pending | accepted | rejected` — daha önce istek gönderildiyse.
  final String? joinRequestStatus;

  static const open = RoomAccessStatus(passwordProtected: false);
}

sealed class PasswordVerifyResult {
  const PasswordVerifyResult();
}

class PasswordVerified extends PasswordVerifyResult {
  const PasswordVerified({required this.accessToken, required this.expiresAt});
  final String accessToken;
  final DateTime expiresAt;
}

class PasswordRejected extends PasswordVerifyResult {
  const PasswordRejected({
    required this.remainingAttempts,
    required this.locked,
    required this.message,
  });
  final int remainingAttempts;
  final bool locked;
  final String message;
}

enum JoinRequestState { pending, accepted, rejected }

JoinRequestState? parseJoinRequestState(Object? raw) {
  switch (raw?.toString().toLowerCase()) {
    case 'pending':
      return JoinRequestState.pending;
    case 'accepted':
      return JoinRequestState.accepted;
    case 'rejected':
      return JoinRequestState.rejected;
  }
  return null;
}

/// `POST join-request` sonucu.
class JoinRequestSent {
  const JoinRequestSent({required this.requestId, required this.alreadySent, this.state});
  final String requestId;

  /// 409 ALREADY_REQUESTED — kullanıcı bu oda için zaten istek göndermiş.
  final bool alreadySent;
  final JoinRequestState? state;
}

/// Oda sahibinin gördüğü bekleyen istek.
class PendingJoinRequest {
  const PendingJoinRequest({
    required this.id,
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;

  /// Popup'ta gösterilen ad: `@kullaniciadi` varsa o, yoksa görünen ad.
  String get handle {
    final u = username?.trim() ?? '';
    return u.isNotEmpty ? '@$u' : name;
  }
}
