import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/util/json_util.dart';

/// Backend `team` nesnesi veya `favoriteTeam` ile eşleşen takım bilgisi.
class UserTeamInfo extends Equatable {
  const UserTeamInfo({
    this.id,
    this.name,
    this.primaryColor,
    this.secondaryColor,
    this.logoUrl,
    this.flagUrl,
    this.flagEmoji,
  });

  factory UserTeamInfo.fromJson(Map<String, dynamic> json) {
    return UserTeamInfo(
      id: pick(json, ['id', 'teamId', 'slug'])?.toString(),
      name: pick(json, ['name', 'title', 'displayName'])?.toString(),
      primaryColor: _colorString(
        pick(json, ['primaryColor', 'primary_color', 'color', 'mainColor']),
      ),
      secondaryColor: _colorString(
        pick(json, ['secondaryColor', 'secondary_color', 'accentColor']),
      ),
      logoUrl: pick(json, ['logoUrl', 'logo', 'image', 'badgeUrl'])?.toString(),
      flagUrl: pick(json, ['flagUrl', 'flag', 'flagImage'])?.toString(),
      flagEmoji: pick(json, ['flagEmoji', 'emoji'])?.toString(),
    );
  }

  static String? _colorString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  final String? id;
  final String? name;
  final String? primaryColor;
  final String? secondaryColor;
  final String? logoUrl;
  final String? flagUrl;
  final String? flagEmoji;

  @override
  List<Object?> get props =>
      [id, name, primaryColor, secondaryColor, logoUrl, flagUrl, flagEmoji];
}

/// Giriş banner / VIP overlay renkleri — takım veya Türkiye varsayılanı.
class EntranceTheme extends Equatable {
  const EntranceTheme({
    required this.primary,
    required this.secondary,
    this.teamName,
    this.logoUrl,
    this.flagEmoji,
    this.isDefaultTurkey = false,
  });

  final Color primary;
  final Color secondary;
  final String? teamName;
  final String? logoUrl;
  final String? flagEmoji;
  final bool isDefaultTurkey;

  static const turkey = EntranceTheme(
    primary: Color(0xFFE30A17),
    secondary: Color(0xFFFFFFFF),
    flagEmoji: '🇹🇷',
    isDefaultTurkey: true,
  );

  LinearGradient get bannerGradient => LinearGradient(
        colors: [
          primary.withValues(alpha: 0.42),
          secondary.withValues(alpha: 0.28),
        ],
      );

  LinearGradient get titleGradient => LinearGradient(
        colors: [primary, Color.lerp(primary, secondary, 0.45) ?? secondary],
      );

  Color get borderColor => Color.lerp(primary, const Color(0xFFFFD700), 0.35)!;

  Color get glowColor => primary.withValues(alpha: 0.38);

  Color get iconColor => Color.lerp(primary, const Color(0xFFFFD700), 0.25)!;

  @override
  List<Object?> get props =>
      [primary, secondary, teamName, logoUrl, flagEmoji, isDefaultTurkey];
}

/// Yerel takım kataloğu — `favoriteTeam` string eşlemesi (API renk yoksa).
abstract final class TeamCatalog {
  static const options = <_TeamOption>[
    _TeamOption(
      key: 'galatasaray',
      label: 'Galatasaray',
      primary: Color(0xFFA90432),
      secondary: Color(0xFFFDB912),
    ),
    _TeamOption(
      key: 'fenerbahce',
      label: 'Fenerbahçe',
      primary: Color(0xFF0B2C4A),
      secondary: Color(0xFFFFED00),
    ),
    _TeamOption(
      key: 'besiktas',
      label: 'Beşiktaş',
      primary: Color(0xFF000000),
      secondary: Color(0xFFFFFFFF),
    ),
    _TeamOption(
      key: 'trabzonspor',
      label: 'Trabzonspor',
      primary: Color(0xFF6B0F1A),
      secondary: Color(0xFF5BC2E7),
    ),
    _TeamOption(
      key: 'basaksehir',
      label: 'Başakşehir',
      primary: Color(0xFF1E3A8A),
      secondary: Color(0xFFF97316),
    ),
    _TeamOption(
      key: 'antalyaspor',
      label: 'Antalyaspor',
      primary: Color(0xFFDC2626),
      secondary: Color(0xFFFFFFFF),
    ),
  ];

  static List<String> get labels => options.map((o) => o.label).toList();

  static EntranceTheme resolve({
    String? favoriteTeam,
    Map<String, dynamic>? teamJson,
  }) {
    if (teamJson != null && teamJson.isNotEmpty) {
      final info = UserTeamInfo.fromJson(teamJson);
      final primary = _parseColor(info.primaryColor);
      final secondary = _parseColor(info.secondaryColor);
      if (primary != null && secondary != null) {
        return EntranceTheme(
          primary: primary,
          secondary: secondary,
          teamName: info.name,
          logoUrl: info.logoUrl ?? info.flagUrl,
          flagEmoji: info.flagEmoji,
        );
      }
      if (info.name != null && info.name!.trim().isNotEmpty) {
        final fromName = _fromFavoriteTeam(info.name);
        if (fromName != null) {
          return fromName.copyWith(
            teamName: info.name,
            logoUrl: info.logoUrl ?? info.flagUrl ?? fromName.logoUrl,
            flagEmoji: info.flagEmoji ?? fromName.flagEmoji,
          );
        }
      }
    }

    final fromFavorite = _fromFavoriteTeam(favoriteTeam);
    if (fromFavorite != null) return fromFavorite;

    return EntranceTheme.turkey;
  }

  static EntranceTheme? _fromFavoriteTeam(String? raw) {
    final norm = _normalize(raw);
    if (norm.isEmpty) return null;
    for (final o in options) {
      if (norm == o.key ||
          norm == _normalize(o.label) ||
          norm.contains(o.key) ||
          _normalize(o.label).contains(norm)) {
        return EntranceTheme(
          primary: o.primary,
          secondary: o.secondary,
          teamName: o.label,
        );
      }
    }
    return EntranceTheme(
      primary: EntranceTheme.turkey.primary,
      secondary: EntranceTheme.turkey.secondary,
      teamName: raw?.trim(),
      flagEmoji: EntranceTheme.turkey.flagEmoji,
      isDefaultTurkey: true,
    );
  }

  static String? labelForKey(String? raw) {
    final norm = _normalize(raw);
    if (norm.isEmpty) return null;
    for (final o in options) {
      if (norm == o.key || norm == _normalize(o.label)) return o.label;
    }
    return raw?.trim();
  }

  static String? keyForLabel(String? label) {
    final norm = _normalize(label);
    for (final o in options) {
      if (norm == _normalize(o.label) || norm == o.key) return o.key;
    }
    return label?.trim().toLowerCase();
  }

  static String _normalize(String? raw) {
    if (raw == null) return '';
    return raw
        .toLowerCase()
        .trim()
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
  }

  static Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) {
      final v = int.tryParse(s, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    if (s.length == 8) {
      final v = int.tryParse(s, radix: 16);
      if (v != null) return Color(v);
    }
    return null;
  }
}

class _TeamOption {
  const _TeamOption({
    required this.key,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final String key;
  final String label;
  final Color primary;
  final Color secondary;
}

extension _EntranceThemeCopy on EntranceTheme {
  EntranceTheme copyWith({
    Color? primary,
    Color? secondary,
    String? teamName,
    String? logoUrl,
    String? flagEmoji,
    bool? isDefaultTurkey,
  }) {
    return EntranceTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      teamName: teamName ?? this.teamName,
      logoUrl: logoUrl ?? this.logoUrl,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      isDefaultTurkey: isDefaultTurkey ?? this.isDefaultTurkey,
    );
  }
}

/// Herhangi bir kullanıcı JSON'undan takım teması çıkarır.
EntranceTheme entranceThemeFromUserJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return EntranceTheme.turkey;
  final teamRaw = json['team'];
  final teamMap = teamRaw is Map ? Map<String, dynamic>.from(teamRaw) : null;
  final favorite = pick(json, ['favoriteTeam', 'favorite_team', 'teamName'])
      ?.toString();
  return TeamCatalog.resolve(favoriteTeam: favorite, teamJson: teamMap);
}
