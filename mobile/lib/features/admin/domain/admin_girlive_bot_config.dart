/// Admin `GET/PUT /api/admin/girlive-bot` — kök bayraklar + `publicMessages`.
class AdminGirLiveBotConfig {
  const AdminGirLiveBotConfig({
    this.enabled = true,
    this.voiceRoomEnabled = true,
    this.liveStreamEnabled = true,
    this.publicMessages = const AdminGirLiveBotPublicMessages(),
    this.words = const [],
    this.whitelist = const [],
  });

  /// Admin'in eklediği yasaklı kelimeler (varsayılan listeye ek):
  /// `{word, severity: LOW|MEDIUM|HIGH|CRITICAL, prefix}`.
  final List<Map<String, dynamic>> words;

  /// Yanlış pozitifleri önleyen güvenli kelimeler.
  final List<String> whitelist;

  /// Genel GirLive bot (PK, karşılama, moderasyon tetikleyicileri).
  final bool enabled;

  /// Sesli sohbet odalarında herkese açık bot mesajları.
  final bool voiceRoomEnabled;

  /// Canlı yayın / video akışında herkese açık bot mesajları.
  final bool liveStreamEnabled;

  final AdminGirLiveBotPublicMessages publicMessages;

  bool get publicMessageControlsActive =>
      enabled && publicMessages.enabled;

  AdminGirLiveBotConfig copyWith({
    bool? enabled,
    bool? voiceRoomEnabled,
    bool? liveStreamEnabled,
    AdminGirLiveBotPublicMessages? publicMessages,
    List<Map<String, dynamic>>? words,
    List<String>? whitelist,
  }) {
    return AdminGirLiveBotConfig(
      words: words ?? this.words,
      whitelist: whitelist ?? this.whitelist,
      enabled: enabled ?? this.enabled,
      voiceRoomEnabled: voiceRoomEnabled ?? this.voiceRoomEnabled,
      liveStreamEnabled: liveStreamEnabled ?? this.liveStreamEnabled,
      publicMessages: publicMessages ?? this.publicMessages,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        // Sunucu yalnız tek bir `enabled` anahtarı bilir; oda / yayın ayrımı yok.
        'publicMessages': publicMessages.toJson(),
        'words': words,
        'whitelist': whitelist,
      };

  factory AdminGirLiveBotConfig.fromJson(Map<String, dynamic>? json) {
    final raw = json ?? const <String, dynamic>{};
    // Backend GET: `{ config: {enabled, words, whitelist, …}, publicMessages }`
    // — `enabled` iç içe `config` altında; önceden hep varsayılan (açık) okunuyordu.
    final root = <String, dynamic>{
      if (raw['config'] is Map) ...Map<String, dynamic>.from(raw['config'] as Map),
      ...raw,
    };
    final pmRaw = root['publicMessages'];
    final wordsRaw = root['words'];
    final whitelistRaw = root['whitelist'];
    return AdminGirLiveBotConfig(
      enabled: _boolFromMap(
        root,
        const ['enabled', 'botEnabled', 'girliveBotEnabled'],
        defaultValue: true,
      ),
      voiceRoomEnabled: _boolFromMap(
        root,
        const [
          'voiceRoomEnabled',
          'chatRoomEnabled',
          'roomEnabled',
          'voiceEnabled',
        ],
        defaultValue: true,
      ),
      liveStreamEnabled: _boolFromMap(
        root,
        const [
          'liveStreamEnabled',
          'streamEnabled',
          'videoStreamEnabled',
          'liveEnabled',
        ],
        defaultValue: true,
      ),
      words: wordsRaw is List
          ? [
              for (final w in wordsRaw)
                if (w is Map && '${w['word'] ?? ''}'.trim().isNotEmpty)
                  Map<String, dynamic>.from(w),
            ]
          : const [],
      whitelist: whitelistRaw is List
          ? [for (final w in whitelistRaw) '$w'.trim()].where((w) => w.isNotEmpty).toList()
          : const [],
      publicMessages: pmRaw is Map
          ? AdminGirLiveBotPublicMessages.fromJson(
              Map<String, dynamic>.from(pmRaw),
            )
          : const AdminGirLiveBotPublicMessages(),
    );
  }
}

/// `publicMessages` alt alanı.
class AdminGirLiveBotPublicMessages {
  const AdminGirLiveBotPublicMessages({
    this.enabled = true,
    this.jetonPromoEnabled = true,
    this.pkStartEnabled = true,
    this.pkMidReminderEnabled = false,
    this.pkEndEnabled = true,
    this.pastPkMotivationEnabled = false,
    this.welcomeLeaveEnabled = true,
    this.minMessageIntervalSec = 30,
    this.templates = const {},
  });

  /// Herkese açık otomatik mesajlar (PK, jeton, hoş geldin).
  final bool enabled;

  final bool jetonPromoEnabled;
  final bool pkStartEnabled;
  final bool pkMidReminderEnabled;
  final bool pkEndEnabled;
  final bool pastPkMotivationEnabled;
  final bool welcomeLeaveEnabled;
  final int minMessageIntervalSec;
  final Map<String, String> templates;

  AdminGirLiveBotPublicMessages copyWith({
    bool? enabled,
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
      enabled: enabled ?? this.enabled,
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
        'enabled': enabled,
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
    if (json == null || json.isEmpty) {
      return const AdminGirLiveBotPublicMessages();
    }
    final tplRaw = json['templates'];
    final templates = <String, String>{};
    if (tplRaw is Map) {
      for (final e in tplRaw.entries) {
        templates['${e.key}'] = '${e.value}';
      }
    }
    return AdminGirLiveBotPublicMessages(
      enabled: _boolFromMap(
        json,
        const ['enabled', 'publicMessagesEnabled'],
        defaultValue: true,
      ),
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

bool _boolFromMap(
  Map<String, dynamic> map,
  List<String> keys, {
  required bool defaultValue,
}) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final v = map[key];
    if (v is bool) return v;
    if (v == true || v == 1 || v == 'true' || v == '1') return true;
    if (v == false || v == 0 || v == 'false' || v == '0') return false;
  }
  return defaultValue;
}
