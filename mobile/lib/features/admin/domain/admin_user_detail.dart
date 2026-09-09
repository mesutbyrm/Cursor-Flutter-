import '../../../core/util/json_util.dart';
import 'admin_user_util.dart';

/// Admin komuta merkezi — birleştirilmiş kullanıcı görünümü.
class AdminUserDetail {
  const AdminUserDetail({
    required this.userId,
    this.raw = const {},
    this.username,
    this.displayName,
    this.email,
    this.bio,
    this.avatarUrl,
    this.role = 'user',
    this.membership = 'basic',
    this.jeton = 0,
    this.cfc = 0,
    this.isOnline = false,
    this.lastSeenAt,
    this.memberSince,
    this.liveStreamCount = 0,
    this.voiceRoomCount = 0,
    this.giftsSentCount = 0,
    this.giftsReceivedCount = 0,
    this.totalSpentJeton = 0,
    this.totalSpentCfc = 0,
    this.adsWatched = 0,
    this.followers = 0,
    this.following = 0,
    this.profileViews = 0,
    this.isPsychic = false,
    this.psychicStatus,
    this.canOpenLiveStream,
    this.canOpenVoiceRoom,
    this.isBanned = false,
    this.banReason,
  });

  final String userId;
  final Map<String, dynamic> raw;
  final String? username;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final String role;
  final String membership;
  final int jeton;
  final int cfc;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? memberSince;
  final int liveStreamCount;
  final int voiceRoomCount;
  final int giftsSentCount;
  final int giftsReceivedCount;
  final int totalSpentJeton;
  final int totalSpentCfc;
  final int adsWatched;
  final int followers;
  final int following;
  final int profileViews;
  final bool isPsychic;
  final String? psychicStatus;
  final bool? canOpenLiveStream;
  final bool? canOpenVoiceRoom;
  final bool isBanned;
  final String? banReason;

  String get label {
    if (username != null && username!.isNotEmpty) return '@$username';
    return displayName ?? userId;
  }

  factory AdminUserDetail.fromMaps({
    required String userId,
    Map<String, dynamic>? admin,
    Map<String, dynamic>? publicProfile,
    Map<String, dynamic>? stats,
  }) {
    final merged = <String, dynamic>{
      ...?publicProfile,
      ...?admin,
      if (stats != null) ...stats,
    };

    int readInt(List<String> keys) {
      for (final k in keys) {
        final v = pick(merged, [k]);
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
        }
      }
      return 0;
    }

    bool readBool(List<String> keys) {
      for (final k in keys) {
        final v = pick(merged, [k]);
        if (v is bool) return v;
        if (v == 1 || v == '1' || v == 'true') return true;
      }
      return false;
    }

    DateTime? readDate(List<String> keys) {
      for (final k in keys) {
        final v = pick(merged, [k])?.toString();
        if (v == null || v.isEmpty) continue;
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.toLocal();
      }
      return null;
    }

    bool? readOptionalBool(List<String> keys) {
      for (final k in keys) {
        final v = pick(merged, [k]);
        if (v is bool) return v;
        if (v == 1 || v == '1' || v == 'true') return true;
        if (v == 0 || v == '0' || v == 'false') return false;
      }
      return null;
    }

    final psychic = pick(merged, [
      'isFortuneTeller',
      'isPsychic',
      'isTeller',
      'fortuneTeller',
    ]);

    return AdminUserDetail(
      userId: userId,
      raw: merged,
      username: pick(merged, ['username', 'userName', 'handle'])?.toString(),
      displayName: pick(merged, [
        'displayName',
        'name',
        'fullName',
      ])?.toString(),
      email: pick(merged, ['email'])?.toString(),
      bio: pick(merged, ['bio', 'about'])?.toString(),
      avatarUrl: pick(merged, [
        'avatarUrl',
        'avatar',
        'image',
        'profileImage',
      ])?.toString(),
      role: pick(merged, ['role', 'userRole'])?.toString() ?? 'user',
      membership:
          pick(merged, ['membership', 'membershipTier', 'vipTier'])?.toString() ??
              'basic',
      jeton: readInt([
        'coins',
        'jeton',
        'jetonBalance',
        'credits',
        'balance',
      ]),
      cfc: readInt(['cfc', 'cfcBalance', 'cfcCoins']),
      isOnline: readBool(['isOnline', 'online', 'is_online']),
      lastSeenAt: readDate([
        'lastSeenAt',
        'lastOnlineAt',
        'lastActiveAt',
        'lastLoginAt',
      ]),
      memberSince: readDate([
        'createdAt',
        'memberSince',
        'registeredAt',
        'joinedAt',
      ]),
      liveStreamCount: readInt([
        'liveStreamCount',
        'liveStreams',
        'streamsCount',
        'broadcastCount',
      ]),
      voiceRoomCount: readInt([
        'voiceRoomCount',
        'roomsOpened',
        'chatRoomsCreated',
      ]),
      giftsSentCount: readInt(['giftsSentCount', 'giftsSent', 'sentGifts']),
      giftsReceivedCount: readInt([
        'giftsReceivedCount',
        'giftsReceived',
        'receivedGifts',
      ]),
      totalSpentJeton: readInt([
        'totalSpentJeton',
        'jetonSpent',
        'coinsSpent',
        'totalSpent',
      ]),
      totalSpentCfc: readInt(['totalSpentCfc', 'cfcSpent']),
      adsWatched: readInt([
        'adsWatched',
        'adWatchCount',
        'watchAdCount',
        'rewardedAds',
      ]),
      followers: readInt(['followers', 'followersCount']),
      following: readInt(['following', 'followingCount']),
      profileViews: readInt(['profileViews', 'viewCount']),
      isPsychic: psychic == true ||
          pick(merged, ['applicationStatus'])?.toString() == 'approved' ||
          pick(merged, ['tellerStatus'])?.toString() == 'approved',
      psychicStatus: pick(merged, [
        'applicationStatus',
        'tellerStatus',
        'psychicStatus',
      ])?.toString(),
      canOpenLiveStream: readOptionalBool([
        'canOpenLiveStream',
        'canBroadcast',
        'liveStreamAllowed',
      ]),
      canOpenVoiceRoom: readOptionalBool([
        'canOpenVoiceRoom',
        'canCreateRoom',
        'voiceRoomAllowed',
      ]),
      isBanned: readBool(['isBanned', 'banned', 'isSuspended']),
      banReason: pick(merged, ['banReason', 'suspensionReason'])?.toString(),
    );
  }

  AdminUserDetail merge(AdminUserDetail other) {
    return AdminUserDetail.fromMaps(
      userId: userId,
      admin: {...raw, ...other.raw},
      publicProfile: other.raw,
      stats: other.raw,
    );
  }
}

/// Üyelik süresi — okunabilir TR metin.
String formatMembershipTenure(DateTime? since) {
  if (since == null) return '—';
  final now = DateTime.now();
  var diff = now.difference(since);
  if (diff.isNegative) diff = Duration.zero;

  final years = diff.inDays ~/ 365;
  final months = (diff.inDays % 365) ~/ 30;
  final weeks = (diff.inDays % 30) ~/ 7;
  final days = diff.inDays % 7;
  final hours = diff.inHours % 24;

  final parts = <String>[];
  if (years > 0) parts.add('$years yıl');
  if (months > 0) parts.add('$months ay');
  if (weeks > 0 && years == 0) parts.add('$weeks hafta');
  if (days > 0 && years == 0 && months == 0) parts.add('$days gün');
  if (parts.isEmpty && hours > 0) parts.add('$hours saat');
  if (parts.isEmpty) parts.add('${diff.inMinutes} dk');
  return parts.take(3).join(' ');
}

String formatLastOnline(DateTime? at, {required bool isOnline}) {
  if (isOnline) return 'Şu an online';
  if (at == null) return '—';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
  if (diff.inDays < 1) return '${diff.inHours} sa önce';
  if (diff.inDays < 30) return '${diff.inDays} gün önce';
  return '${at.day}.${at.month}.${at.year}';
}
