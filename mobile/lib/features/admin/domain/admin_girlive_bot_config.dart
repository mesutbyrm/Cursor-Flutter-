/// Admin `GET/PUT /api/admin/girlive-bot` — `publicMessages` alanı.
class AdminGirLiveBotPublicMessages {
  const AdminGirLiveBotPublicMessages({
    this.jetonPromoEnabled = true,
    this.pkStartEnabled = true,
    this.pkMidReminderEnabled = false,
    this.pkEndEnabled = true,
    this.pastPkMotivationEnabled = false,
    this.welcomeLeaveEnabled = true,
    this.minMessageIntervalSec = 30,
    this.templates = const {},
  });

  final bool jetonPromoEnabled;
  final bool pkStartEnabled;
  final bool pkMidReminderEnabled;
  final bool pkEndEnabled;
  final bool pastPkMotivationEnabled;
  final bool welcomeLeaveEnabled;
  final int minMessageIntervalSec;
  final Map<String, String> templates;

  AdminGirLiveBotPublicMessages copyWith({
    bool? jetonPromoEnabled,
    bool? pkStartEnabled,
    bool? pkMidReminderEnabled,
    bool? pkEndEnabled,
    bool? pastPkMotivationEnabled,
    bool? welcomeLeaveEnabled,
    int? minMessageIntervalSec,
    Map<String, String>? templates,
  }) {
    return AdminGirLiveBotPublicMessages(
      jetonPromoEnabled: jetonPromoEnabled ?? this.jetonPromoEnabled,
      pkStartEnabled: pkStartEnabled ?? this.pkStartEnabled,
      pkMidReminderEnabled:
          pkMidReminderEnabled ?? this.pkMidReminderEnabled,
      pkEndEnabled: pkEndEnabled ?? this.pkEndEnabled,
      pastPkMotivationEnabled:
          pastPkMotivationEnabled ?? this.pastPkMotivationEnabled,
      welcomeLeaveEnabled: welcomeLeaveEnabled ?? this.welcomeLeaveEnabled,
      minMessageIntervalSec:
          minMessageIntervalSec ?? this.minMessageIntervalSec,
      templates: templates ?? this.templates,
    );
  }

  Map<String, dynamic> toJson() => {
        'jetonPromoEnabled': jetonPromoEnabled,
        'pkStartEnabled': pkStartEnabled,
        'pkMidReminderEnabled': pkMidReminderEnabled,
        'pkEndEnabled': pkEndEnabled,
        'pastPkMotivationEnabled': pastPkMotivationEnabled,
        'welcomeLeaveEnabled': welcomeLeaveEnabled,
        'minMessageIntervalSec': minMessageIntervalSec,
        'templates': templates,
      };

  factory AdminGirLiveBotPublicMessages.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const AdminGirLiveBotPublicMessages();
    final tplRaw = json['templates'];
    final templates = <String, String>{};
    if (tplRaw is Map) {
      for (final e in tplRaw.entries) {
        templates['${e.key}'] = '${e.value}';
      }
    }
    return AdminGirLiveBotPublicMessages(
      jetonPromoEnabled: json['jetonPromoEnabled'] == true,
      pkStartEnabled: json['pkStartEnabled'] != false,
      pkMidReminderEnabled: json['pkMidReminderEnabled'] == true,
      pkEndEnabled: json['pkEndEnabled'] != false,
      pastPkMotivationEnabled: json['pastPkMotivationEnabled'] == true,
      welcomeLeaveEnabled: json['welcomeLeaveEnabled'] != false,
      minMessageIntervalSec:
          (json['minMessageIntervalSec'] as num?)?.toInt() ?? 30,
      templates: templates,
    );
  }
}
