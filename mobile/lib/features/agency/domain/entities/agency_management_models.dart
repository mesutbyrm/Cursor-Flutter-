import '../../../../core/util/json_util.dart';

/// Ajans yönetimi (keşif, performans, vaat, hedef, hak ediş, yayıncı paneli)
/// görünüm modelleri. Tüm sayılar sunucudan gelir; istemci hesap yapmaz.

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
String? _str(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

double _dbl(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String periodLabelTr(String? p) => switch (p) {
      'daily' => 'Günlük',
      'weekly' => 'Haftalık',
      'monthly' => 'Aylık',
      _ => p ?? '',
    };

/// Dakikayı "12 sa 30 dk" biçiminde yazar.
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0 dk';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m dk';
  if (m == 0) return '$h sa';
  return '$h sa $m dk';
}

class AgencyUserRef {
  const AgencyUserRef({required this.id, this.name, this.username, this.image});
  final String id;
  final String? name;
  final String? username;
  final String? image;

  String get display => name ?? (username != null ? '@$username' : 'Kullanıcı');

  static AgencyUserRef fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyUserRef(
      id: '${m['id'] ?? ''}',
      name: _str(m['name']),
      username: _str(m['username']),
      image: _str(m['image']),
    );
  }
}

class AgencyCard {
  const AgencyCard({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.level,
    required this.verified,
    required this.featured,
    required this.activeMembers,
    required this.verifiedHours30d,
    this.targetSuccessRate,
    required this.closedTargets90d,
    required this.activePromises,
  });

  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String level;
  final bool verified;
  final bool featured;
  final int activeMembers;
  final double verifiedHours30d;

  /// Kapanmış hedef dönemi yoksa null — "veri yok" gösterilir.
  final double? targetSuccessRate;
  final int closedTargets90d;
  final int activePromises;

  String get levelLabel => switch (level) {
        'diamond' => 'Elmas',
        'gold' => 'Altın',
        'silver' => 'Gümüş',
        _ => 'Bronz',
      };

  static AgencyCard fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyCard(
      id: '${m['id'] ?? ''}',
      name: '${m['name'] ?? ''}',
      description: _str(m['description']),
      logoUrl: _str(m['logoUrl']),
      level: '${m['level'] ?? 'bronze'}',
      verified: m['verified'] == true,
      featured: m['featured'] == true,
      activeMembers: asInt(m['activeMembers']),
      verifiedHours30d: _dbl(m['verifiedHours30d']),
      targetSuccessRate: m['targetSuccessRate'] == null ? null : _dbl(m['targetSuccessRate']),
      closedTargets90d: asInt(m['closedTargets90d']),
      activePromises: asInt(m['activePromises']),
    );
  }
}

class PromiseVersionView {
  const PromiseVersionView({
    required this.id,
    required this.promiseId,
    required this.title,
    required this.version,
    required this.body,
    required this.measurement,
    this.targetPeriod,
    this.targetMinutes,
    this.minDays,
    required this.bonusJeton,
    this.periodStart,
    this.periodEnd,
    required this.requiresReaccept,
    required this.status,
    this.reviewNote,
    this.acceptedCount = 0,
    this.acceptedAt,
    this.needsAcceptance = false,
    this.previouslyAcceptedVersion,
  });

  final String id;
  final String promiseId;
  final String title;
  final int version;
  final String body;
  final String measurement;
  final String? targetPeriod;
  final int? targetMinutes;
  final int? minDays;
  final int bonusJeton;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool requiresReaccept;
  final String status;
  final String? reviewNote;
  final int acceptedCount;
  final DateTime? acceptedAt;
  final bool needsAcceptance;
  final int? previouslyAcceptedVersion;

  String get statusLabel => switch (status) {
        'pending' => 'Onay bekliyor',
        'approved' => 'Yayında',
        'rejected' => 'Reddedildi',
        'superseded' => 'Eski sürüm',
        'withdrawn' => 'Geri çekildi',
        _ => status,
      };

  String? get targetSummary {
    final t = targetMinutes;
    if (t == null || t <= 0) return null;
    final parts = ['${periodLabelTr(targetPeriod)} ${formatMinutes(t)}'];
    if (minDays != null && minDays! > 0) parts.add('en az $minDays gün');
    if (bonusJeton > 0) parts.add('bonus $bonusJeton Jeton');
    return parts.join(' · ');
  }

  static PromiseVersionView fromJson(dynamic raw, {String? title}) {
    final m = asJsonMap(raw);
    return PromiseVersionView(
      id: '${m['id'] ?? ''}',
      promiseId: '${m['promiseId'] ?? ''}',
      title: title ?? '${m['title'] ?? ''}',
      version: asInt(m['version']),
      body: '${m['body'] ?? ''}',
      measurement: '${m['measurement'] ?? ''}',
      targetPeriod: _str(m['targetPeriod']),
      targetMinutes: m['targetMinutes'] == null ? null : asInt(m['targetMinutes']),
      minDays: m['minDays'] == null ? null : asInt(m['minDays']),
      bonusJeton: asInt(m['bonusJeton']),
      periodStart: _date(m['periodStart']),
      periodEnd: _date(m['periodEnd']),
      requiresReaccept: m['requiresReaccept'] != false,
      status: '${m['status'] ?? ''}',
      reviewNote: _str(m['reviewNote']),
      acceptedCount: asInt(m['acceptedCount']),
      acceptedAt: _date(m['acceptedAt']),
      needsAcceptance: m['needsAcceptance'] == true,
      previouslyAcceptedVersion: m['previouslyAcceptedVersion'] == null ? null : asInt(m['previouslyAcceptedVersion']),
    );
  }
}

class AgencyRelation {
  const AgencyRelation({
    required this.loggedIn,
    this.isMember = false,
    this.inOtherAgency = false,
    this.pendingRequestId,
    this.pendingInviteId,
    this.canApply = false,
  });
  final bool loggedIn;
  final bool isMember;
  final bool inOtherAgency;
  final String? pendingRequestId;
  final String? pendingInviteId;
  final bool canApply;

  static AgencyRelation fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyRelation(
      loggedIn: m['loggedIn'] == true,
      isMember: m['isMember'] == true,
      inOtherAgency: m['inOtherAgency'] == true,
      pendingRequestId: _str(m['pendingRequestId']),
      pendingInviteId: _str(m['pendingInviteId']),
      canApply: m['canApply'] == true,
    );
  }
}

class AgencyDetail {
  const AgencyDetail({
    required this.card,
    required this.acceptsApplications,
    this.owner,
    required this.members,
    required this.promises,
    required this.relation,
  });
  final AgencyCard card;
  final bool acceptsApplications;
  final AgencyUserRef? owner;
  final List<AgencyUserRef> members;
  final List<PromiseVersionView> promises;
  final AgencyRelation relation;

  static AgencyDetail fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final agency = asJsonMap(m['agency']);
    return AgencyDetail(
      card: AgencyCard.fromJson(agency),
      acceptsApplications: agency['acceptsApplications'] != false,
      owner: m['owner'] == null ? null : AgencyUserRef.fromJson(m['owner']),
      members: asJsonList(m['members']).map(AgencyUserRef.fromJson).toList(),
      promises: asJsonList(m['promises']).map((e) => PromiseVersionView.fromJson(e)).toList(),
      relation: AgencyRelation.fromJson(m['relation']),
    );
  }
}

class MemberPerfRow {
  const MemberPerfRow({
    required this.user,
    required this.status,
    this.role,
    required this.verifiedMinutes,
    required this.activeDays,
    required this.sessionCount,
    required this.interruptedCount,
    required this.giftJeton,
    this.targetMinutes,
    this.targetMet,
  });
  final AgencyUserRef user;
  final String status;
  final String? role;
  final int verifiedMinutes;
  final int activeDays;
  final int sessionCount;
  final int interruptedCount;
  final int giftJeton;
  final int? targetMinutes;
  final bool? targetMet;

  static MemberPerfRow fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final t = m['target'] == null ? null : asJsonMap(m['target']);
    return MemberPerfRow(
      user: AgencyUserRef.fromJson(m['user']),
      status: '${m['status'] ?? 'active'}',
      role: _str(m['role']),
      verifiedMinutes: asInt(m['verifiedMinutes']),
      activeDays: asInt(m['activeDays']),
      sessionCount: asInt(m['sessionCount']),
      interruptedCount: asInt(m['interruptedCount']),
      giftJeton: asInt(m['giftJeton']),
      targetMinutes: t == null ? null : asInt(t['targetMinutes']),
      targetMet: t == null ? null : t['met'] == true,
    );
  }
}

class AgencyPerformanceReport {
  const AgencyPerformanceReport({
    required this.period,
    required this.totalMinutes,
    required this.totalGiftJeton,
    required this.targetsMet,
    required this.targetsTotal,
    required this.members,
  });
  final String period;
  final int totalMinutes;
  final int totalGiftJeton;
  final int targetsMet;
  final int targetsTotal;
  final List<MemberPerfRow> members;

  static AgencyPerformanceReport fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final t = asJsonMap(m['totals']);
    return AgencyPerformanceReport(
      period: '${m['period'] ?? ''}',
      totalMinutes: asInt(t['verifiedMinutes']),
      totalGiftJeton: asInt(t['giftJeton']),
      targetsMet: asInt(t['targetsMet']),
      targetsTotal: asInt(t['targetsTotal']),
      members: asJsonList(m['members']).map(MemberPerfRow.fromJson).toList(),
    );
  }
}

class TargetProgress {
  const TargetProgress({
    required this.id,
    required this.period,
    required this.targetMinutes,
    this.minDays,
    required this.bonusJeton,
    required this.verifiedMinutes,
    required this.activeDays,
    required this.remainingMinutes,
    required this.met,
    this.promiseVersionId,
  });
  final String id;
  final String period;
  final int targetMinutes;
  final int? minDays;
  final int bonusJeton;
  final int verifiedMinutes;
  final int activeDays;
  final int remainingMinutes;
  final bool met;
  final String? promiseVersionId;

  double get ratio => targetMinutes <= 0 ? 0 : (verifiedMinutes / targetMinutes).clamp(0, 1).toDouble();

  static TargetProgress fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return TargetProgress(
      id: '${m['id'] ?? ''}',
      period: '${m['period'] ?? ''}',
      targetMinutes: asInt(m['targetMinutes']),
      minDays: m['minDays'] == null ? null : asInt(m['minDays']),
      bonusJeton: asInt(m['bonusJeton']),
      verifiedMinutes: asInt(m['verifiedMinutes']),
      activeDays: asInt(m['activeDays']),
      remainingMinutes: asInt(m['remainingMinutes']),
      met: m['met'] == true,
      promiseVersionId: _str(m['promiseVersionId']),
    );
  }
}

class AccrualView {
  const AccrualView({
    required this.id,
    required this.userId,
    this.user,
    required this.period,
    this.periodStart,
    this.periodEnd,
    required this.targetMinutes,
    required this.verifiedMinutes,
    required this.met,
    required this.bonusJeton,
    required this.status,
  });
  final String id;
  final String userId;
  final AgencyUserRef? user;
  final String period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int targetMinutes;
  final int verifiedMinutes;
  final bool met;
  final int bonusJeton;
  final String status;

  bool get payable => status == 'earned';

  String get statusLabel => switch (status) {
        'earned' => 'Kazanıldı · ödenmedi',
        'paying' => 'Ödeniyor',
        'paid' => 'Ödendi',
        'met' => 'Hedef tuttu',
        'not_met' => 'Hedef tutmadı',
        'void' => 'İptal edildi',
        _ => status,
      };

  static AccrualView fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AccrualView(
      id: '${m['id'] ?? ''}',
      userId: '${m['userId'] ?? ''}',
      user: m['user'] == null ? null : AgencyUserRef.fromJson(m['user']),
      period: '${m['period'] ?? ''}',
      periodStart: _date(m['periodStart']),
      periodEnd: _date(m['periodEnd']),
      targetMinutes: asInt(m['targetMinutes']),
      verifiedMinutes: asInt(m['verifiedMinutes']),
      met: m['met'] == true,
      bonusJeton: asInt(m['bonusJeton']),
      status: '${m['status'] ?? ''}',
    );
  }
}

class StreamSessionView {
  const StreamSessionView({
    required this.id,
    this.title,
    this.startedAt,
    this.endedAt,
    required this.live,
    required this.interrupted,
    required this.countedMinutes,
  });
  final String id;
  final String? title;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool live;
  final bool interrupted;
  final int countedMinutes;

  static StreamSessionView fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return StreamSessionView(
      id: '${m['id'] ?? ''}',
      title: _str(m['title']),
      startedAt: _date(m['startedAt']),
      endedAt: _date(m['endedAt']),
      live: m['live'] == true,
      interrupted: m['interrupted'] == true,
      countedMinutes: asInt(m['countedMinutes']),
    );
  }
}

class MembershipHistoryEntry {
  const MembershipHistoryEntry({
    required this.agencyId,
    required this.agencyName,
    this.role,
    this.joinedAt,
    this.leftAt,
    this.endedBy,
  });
  final String agencyId;
  final String agencyName;
  final String? role;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final String? endedBy;

  String get endedByLabel => switch (endedBy) {
        'user' => 'kendi isteğiyle',
        'agency' => 'ajans çıkardı',
        'admin' => 'yönetici',
        'auto' => 'otomatik (yanıtsız talep)',
        'transfer' => 'transfer',
        _ => '',
      };

  static MembershipHistoryEntry fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return MembershipHistoryEntry(
      agencyId: '${m['agencyId'] ?? ''}',
      agencyName: '${m['agencyName'] ?? 'Ajans'}',
      role: _str(m['role']),
      joinedAt: _date(m['joinedAt']),
      leftAt: _date(m['leftAt']),
      endedBy: _str(m['endedBy']),
    );
  }
}

class ModerationEntry {
  const ModerationEntry({required this.kind, required this.action, this.severity, this.createdAt});
  final String kind;
  final String action;
  final String? severity;
  final DateTime? createdAt;

  static ModerationEntry fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return ModerationEntry(
      kind: '${m['kind'] ?? ''}',
      action: '${m['action'] ?? ''}',
      severity: _str(m['severity']),
      createdAt: _date(m['createdAt']),
    );
  }
}

class MemberPerformanceDetail {
  const MemberPerformanceDetail({
    this.user,
    required this.verifiedMinutes,
    required this.activeDays,
    required this.sessionCount,
    required this.interruptedCount,
    required this.daily,
    required this.sessions,
    required this.giftJeton,
    required this.targets,
    required this.accruals,
    required this.bonusEarned,
    required this.bonusPaid,
    required this.history,
    required this.moderation,
  });
  final AgencyUserRef? user;
  final int verifiedMinutes;
  final int activeDays;
  final int sessionCount;
  final int interruptedCount;
  final List<(String, int)> daily;
  final List<StreamSessionView> sessions;
  final int giftJeton;
  final List<TargetProgress> targets;
  final List<AccrualView> accruals;
  final int bonusEarned;
  final int bonusPaid;
  final List<MembershipHistoryEntry> history;
  final List<ModerationEntry> moderation;

  static MemberPerformanceDetail fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final s = asJsonMap(m['summary']);
    final b = asJsonMap(m['bonusTotals']);
    return MemberPerformanceDetail(
      user: m['user'] == null ? null : AgencyUserRef.fromJson(m['user']),
      verifiedMinutes: asInt(s['verifiedMinutes']),
      activeDays: asInt(s['activeDays']),
      sessionCount: asInt(s['sessionCount']),
      interruptedCount: asInt(s['interruptedCount']),
      daily: asJsonList(s['daily']).map((d) => ('${d['date']}', asInt(d['minutes']))).toList(),
      sessions: asJsonList(m['sessions']).map(StreamSessionView.fromJson).toList(),
      giftJeton: asInt(asJsonMap(m['gifts'])['giftJeton']),
      targets: asJsonList(m['targets']).map(TargetProgress.fromJson).toList(),
      accruals: asJsonList(m['accruals']).map(AccrualView.fromJson).toList(),
      bonusEarned: asInt(b['earned']),
      bonusPaid: asInt(b['paid']),
      history: asJsonList(m['membershipHistory']).map(MembershipHistoryEntry.fromJson).toList(),
      moderation: asJsonList(m['moderation']).map(ModerationEntry.fromJson).toList(),
    );
  }
}

class AgencyAnnouncement {
  const AgencyAnnouncement({required this.id, required this.title, required this.body, required this.pinned, this.createdAt});
  final String id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime? createdAt;

  static AgencyAnnouncement fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyAnnouncement(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      body: '${m['body'] ?? ''}',
      pinned: m['pinned'] == true,
      createdAt: _date(m['createdAt']),
    );
  }
}

class JoinRequestView {
  const JoinRequestView({
    required this.id,
    required this.agencyId,
    this.agencyName,
    this.user,
    this.message,
    required this.status,
    this.createdAt,
  });
  final String id;
  final String agencyId;
  final String? agencyName;
  final AgencyUserRef? user;
  final String? message;
  final String status;
  final DateTime? createdAt;

  String get statusLabel => switch (status) {
        'pending' => 'Bekliyor',
        'accepted' => 'Kabul edildi',
        'rejected' => 'Reddedildi',
        'cancelled' => 'İptal',
        _ => status,
      };

  static JoinRequestView fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return JoinRequestView(
      id: '${m['id'] ?? ''}',
      agencyId: '${m['agencyId'] ?? ''}',
      agencyName: _str(m['agencyName']),
      user: m['user'] == null ? null : AgencyUserRef.fromJson(m['user']),
      message: _str(m['message']),
      status: '${m['status'] ?? 'pending'}',
      createdAt: _date(m['createdAt']),
    );
  }
}

class AgencyPromiseGroup {
  const AgencyPromiseGroup({required this.id, required this.title, required this.status, required this.versions});
  final String id;
  final String title;
  final String status;
  final List<PromiseVersionView> versions;

  bool get hasPending => versions.any((v) => v.status == 'pending');

  static AgencyPromiseGroup fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final title = '${m['title'] ?? ''}';
    return AgencyPromiseGroup(
      id: '${m['id'] ?? ''}',
      title: title,
      status: '${m['status'] ?? ''}',
      versions: asJsonList(m['versions']).map((v) => PromiseVersionView.fromJson(v, title: title)).toList(),
    );
  }
}

class PromiseRules {
  const PromiseRules({required this.enabled, required this.maxBonusJeton, required this.maxTargetMinutes, required this.allowedPeriods});
  final bool enabled;
  final int maxBonusJeton;
  final int maxTargetMinutes;
  final List<String> allowedPeriods;

  static PromiseRules fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final periods = (m['allowedPeriods'] is List) ? (m['allowedPeriods'] as List).map((e) => '$e').toList() : <String>['weekly'];
    return PromiseRules(
      enabled: m['enabled'] != false,
      maxBonusJeton: asInt(m['maxBonusJeton']),
      maxTargetMinutes: asInt(m['maxTargetMinutes']),
      allowedPeriods: periods,
    );
  }
}

class AgencyPromisesData {
  const AgencyPromisesData({required this.rules, required this.canEdit, required this.promises});
  final PromiseRules rules;
  final bool canEdit;
  final List<AgencyPromiseGroup> promises;

  static AgencyPromisesData fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyPromisesData(
      rules: PromiseRules.fromJson(m['rules']),
      canEdit: m['canEdit'] == true,
      promises: asJsonList(m['promises']).map(AgencyPromiseGroup.fromJson).toList(),
    );
  }
}

class StaffEntry {
  const StaffEntry({required this.userId, this.user, required this.permissions});
  final String userId;
  final AgencyUserRef? user;
  final List<String> permissions;

  static StaffEntry fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return StaffEntry(
      userId: '${m['userId'] ?? ''}',
      user: m['user'] == null ? null : AgencyUserRef.fromJson(m['user']),
      permissions: (m['permissions'] is List) ? (m['permissions'] as List).map((e) => '$e').toList() : const [],
    );
  }
}

const agencyStaffPermissionLabels = <String, String>{
  'members': 'Üye ve başvuru yönetimi',
  'invites': 'Davet gönderme',
  'reports': 'Performans raporları',
  'announce': 'Duyuru yayımlama',
  'targets': 'Hedef atama ve dönem kapatma',
};

class BroadcasterPanel {
  const BroadcasterPanel({
    this.agencyId,
    this.agencyName,
    this.agencyLogo,
    this.role,
    this.joinedAt,
    this.isOwner = false,
    this.pendingLeave = false,
    required this.totals,
    required this.targets,
    required this.promises,
    required this.acceptedHistory,
    required this.accruals,
    required this.bonusEarned,
    required this.bonusPaid,
    required this.announcements,
    required this.history,
    required this.joinRequests,
    required this.invites,
    required this.rules,
  });

  final String? agencyId;
  final String? agencyName;
  final String? agencyLogo;
  final String? role;
  final DateTime? joinedAt;
  final bool isOwner;
  final bool pendingLeave;

  /// period → (dakika, aktif gün)
  final Map<String, (int, int)> totals;
  final List<TargetProgress> targets;
  final List<PromiseVersionView> promises;
  final List<(String, int?, DateTime?)> acceptedHistory;
  final List<AccrualView> accruals;
  final int bonusEarned;
  final int bonusPaid;
  final List<AgencyAnnouncement> announcements;
  final List<MembershipHistoryEntry> history;
  final List<JoinRequestView> joinRequests;
  final List<(String, String, DateTime?)> invites;
  final Map<String, String> rules;

  bool get hasAgency => agencyId != null;

  static BroadcasterPanel fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final mem = m['membership'] == null ? null : asJsonMap(m['membership']);
    final agency = mem == null ? const <String, dynamic>{} : asJsonMap(mem['agency']);
    final totals = <String, (int, int)>{};
    asJsonMap(m['totals']).forEach((k, v) {
      final t = asJsonMap(v);
      totals[k] = (asInt(t['verifiedMinutes']), asInt(t['activeDays']));
    });
    final b = asJsonMap(m['bonusTotals']);
    return BroadcasterPanel(
      agencyId: mem == null ? null : _str(agency['id']),
      agencyName: _str(agency['name']),
      agencyLogo: _str(agency['logoUrl']),
      role: mem == null ? null : _str(mem['role']),
      joinedAt: mem == null ? null : _date(mem['joinedAt']),
      isOwner: mem?['isOwner'] == true,
      pendingLeave: mem?['pendingLeaveRequest'] != null,
      totals: totals,
      targets: asJsonList(m['targets']).map(TargetProgress.fromJson).toList(),
      promises: asJsonList(m['promises']).map((e) => PromiseVersionView.fromJson(e)).toList(),
      acceptedHistory: asJsonList(m['acceptedHistory'])
          .map((a) => ('${a['title'] ?? 'Vaat'}', a['version'] == null ? null : asInt(a['version']), _date(a['acceptedAt'])))
          .toList(),
      accruals: asJsonList(m['accruals']).map(AccrualView.fromJson).toList(),
      bonusEarned: asInt(b['earned']),
      bonusPaid: asInt(b['paid']),
      announcements: asJsonList(m['announcements']).map(AgencyAnnouncement.fromJson).toList(),
      history: asJsonList(m['history']).map(MembershipHistoryEntry.fromJson).toList(),
      joinRequests: asJsonList(m['joinRequests']).map(JoinRequestView.fromJson).toList(),
      invites: asJsonList(m['invites'])
          .map((i) => ('${asJsonMap(i['agency'])['name'] ?? 'Ajans'}', '${i['status'] ?? ''}', _date(i['createdAt'])))
          .toList(),
      rules: asJsonMap(m['rules']).map((k, v) => MapEntry(k, '$v')),
    );
  }
}

/// Üye listesi satırı (aktif, pasif, bekleyen, ayrılmış, engellenmiş).
class RosterEntry {
  const RosterEntry({required this.user, this.role, this.kind, this.id, this.since, this.until, this.endedBy, this.note});
  final AgencyUserRef user;
  final String? role;

  /// Bekleyenlerde: `request` (başvuru) | `invite` (gönderilen davet).
  final String? kind;
  final String? id;
  final DateTime? since;
  final DateTime? until;
  final String? endedBy;
  final String? note;

  static RosterEntry fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return RosterEntry(
      user: AgencyUserRef.fromJson(m['user']),
      role: _str(m['role']),
      kind: _str(m['kind']),
      id: _str(m['id']),
      since: _date(m['since']),
      until: _date(m['until']),
      endedBy: _str(m['endedBy']),
      note: _str(m['note']),
    );
  }
}

class AgencyRoster {
  const AgencyRoster({required this.active, required this.inactive, required this.pending, required this.left, required this.blocked});
  final List<RosterEntry> active;
  final List<RosterEntry> inactive;
  final List<RosterEntry> pending;
  final List<RosterEntry> left;
  final List<RosterEntry> blocked;

  static AgencyRoster fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    List<RosterEntry> l(String k) => asJsonList(m[k]).map(RosterEntry.fromJson).toList();
    return AgencyRoster(active: l('active'), inactive: l('inactive'), pending: l('pending'), left: l('left'), blocked: l('blocked'));
  }
}

/// Yönetici: onay bekleyen / işlenmiş vaat sürümü.
class AdminPromiseVersion {
  const AdminPromiseVersion({required this.version, required this.agencyName, required this.agencyId, this.currentApproved});
  final PromiseVersionView version;
  final String agencyName;
  final String agencyId;
  final PromiseVersionView? currentApproved;

  static AdminPromiseVersion fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AdminPromiseVersion(
      version: PromiseVersionView.fromJson(m),
      agencyName: '${m['agencyName'] ?? 'Ajans'}',
      agencyId: '${m['agencyId'] ?? ''}',
      currentApproved: m['currentApproved'] == null ? null : PromiseVersionView.fromJson(m['currentApproved'], title: '${m['title'] ?? ''}'),
    );
  }
}

class AgencyAlertView {
  const AgencyAlertView({required this.kind, required this.severity, required this.agencyName, required this.message, this.at, required this.refCount});
  final String kind;
  final String severity;
  final String agencyName;
  final String message;
  final DateTime? at;
  final int refCount;

  String get kindLabel => switch (kind) {
        'large_transfer' => 'Büyük aktarım',
        'repeat_target' => 'Aynı kullanıcıya sık aktarım',
        'new_account' => 'Yeni hesaba aktarım',
        'self_dealing' => 'Sahibine/yetkilisine aktarım',
        'daily_outflow' => 'Günlük çıkış eşiği',
        'cancelled_orders' => 'İptal edilen siparişler',
        _ => kind,
      };

  static AgencyAlertView fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    return AgencyAlertView(
      kind: '${m['kind'] ?? ''}',
      severity: '${m['severity'] ?? 'medium'}',
      agencyName: '${m['agencyName'] ?? 'Ajans'}',
      message: '${m['message'] ?? ''}',
      at: _date(m['at']),
      refCount: (m['refs'] is List) ? (m['refs'] as List).length : 0,
    );
  }
}
