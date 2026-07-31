import '../../util/json_util.dart';

class MobileConfigMaintenance {
  const MobileConfigMaintenance({
    this.enabled = false,
    this.message,
  });

  final bool enabled;
  final String? message;

  factory MobileConfigMaintenance.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MobileConfigMaintenance();
    return MobileConfigMaintenance(
      enabled: json['enabled'] == true,
      message: json['message']?.toString(),
    );
  }
}

class MobileConfigVersion {
  const MobileConfigVersion({
    this.current,
    this.minimum,
    this.latest,
    this.forceUpdate = false,
    this.optionalUpdate = false,
    this.forceUpdateMessage,
    this.optionalUpdateMessage,
    this.storeUrl,
  });

  final String? current;
  final String? minimum;
  final String? latest;
  final bool forceUpdate;
  final bool optionalUpdate;
  final String? forceUpdateMessage;
  final String? optionalUpdateMessage;
  final String? storeUrl;

  factory MobileConfigVersion.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MobileConfigVersion();
    return MobileConfigVersion(
      current: json['current']?.toString(),
      minimum: json['minimum']?.toString(),
      latest: json['latest']?.toString(),
      forceUpdate: json['forceUpdate'] == true,
      optionalUpdate: json['optionalUpdate'] == true,
      forceUpdateMessage: json['forceUpdateMessage']?.toString(),
      optionalUpdateMessage: json['optionalUpdateMessage']?.toString(),
      storeUrl: pick(json, ['storeUrl', 'storeURL', 'url'])?.toString(),
    );
  }
}

class MobileConfigFeatures {
  const MobileConfigFeatures({
    this.liveStream = true,
    this.chat = true,
    this.shortVideos = true,
    this.games = true,
    this.stories = true,
    this.aiFortune = true,
    this.liveTeller = true,
    this.pkBattle = true,
  });

  final bool liveStream;
  final bool chat;
  final bool shortVideos;
  final bool games;
  final bool stories;
  final bool aiFortune;
  final bool liveTeller;
  final bool pkBattle;

  factory MobileConfigFeatures.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MobileConfigFeatures();
    bool flag(String key) => json[key] != false;
    return MobileConfigFeatures(
      liveStream: flag('liveStream'),
      chat: flag('chat'),
      shortVideos: flag('shortVideos'),
      games: flag('games'),
      stories: flag('stories'),
      aiFortune: flag('aiFortune'),
      liveTeller: flag('liveTeller'),
      pkBattle: flag('pkBattle'),
    );
  }
}

class MobileConfigLinks {
  const MobileConfigLinks({
    this.terms,
    this.privacy,
    this.support,
  });

  final String? terms;
  final String? privacy;
  final String? support;

  factory MobileConfigLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MobileConfigLinks();
    return MobileConfigLinks(
      terms: json['terms']?.toString(),
      privacy: json['privacy']?.toString(),
      support: json['support']?.toString(),
    );
  }
}

/// `GET /api/mobile/config` yanıtı.
class MobileConfig {
  const MobileConfig({
    required this.maintenance,
    required this.version,
    required this.features,
    this.ads = const {},
    required this.links,
    this.raw = const {},
  });

  final MobileConfigMaintenance maintenance;
  final MobileConfigVersion version;
  final MobileConfigFeatures features;
  final Map<String, dynamic> ads;
  final MobileConfigLinks links;
  final Map<String, dynamic> raw;

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    return MobileConfig(
      maintenance: MobileConfigMaintenance.fromJson(
        json['maintenance'] is Map
            ? Map<String, dynamic>.from(json['maintenance'] as Map)
            : null,
      ),
      version: MobileConfigVersion.fromJson(
        json['version'] is Map
            ? Map<String, dynamic>.from(json['version'] as Map)
            : null,
      ),
      features: MobileConfigFeatures.fromJson(
        json['features'] is Map
            ? Map<String, dynamic>.from(json['features'] as Map)
            : null,
      ),
      ads: json['ads'] is Map
          ? Map<String, dynamic>.from(json['ads'] as Map)
          : const {},
      links: MobileConfigLinks.fromJson(
        json['links'] is Map
            ? Map<String, dynamic>.from(json['links'] as Map)
            : null,
      ),
      raw: json,
    );
  }

  factory MobileConfig.parseRoot(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == true && map['data'] is Map) {
        return MobileConfig.fromJson(
          Map<String, dynamic>.from(map['data'] as Map),
        );
      }
      if (map['data'] is Map) {
        return MobileConfig.fromJson(
          Map<String, dynamic>.from(map['data'] as Map),
        );
      }
      return MobileConfig.fromJson(map);
    }
    return const MobileConfig(
      maintenance: MobileConfigMaintenance(),
      version: MobileConfigVersion(),
      features: MobileConfigFeatures(),
      links: MobileConfigLinks(),
    );
  }
}
