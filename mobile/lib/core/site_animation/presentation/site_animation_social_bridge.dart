import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/voice_hub/domain/voice_official_join.dart';
import '../domain/site_animation_tier.dart';
import 'site_animation_provider.dart';
import 'widgets/site_animation_context_host.dart';

typedef _SiteAnimationRead = T Function<T>(ProviderListenable<T> provider);

bool _isSocialPostAnnouncement(String raw) =>
    VoiceOfficialJoin.isHomeBannerSocialPostAnnouncement(raw);

void _dispatchSiteAnimationSocialEntrance(_SiteAnimationRead read, String bannerLine) {
  final trimmed = bannerLine.trim();
  if (trimmed.isEmpty) return;
  if (VoiceOfficialJoin.isHomeBannerGiftAnnouncement(trimmed)) return;
  if (_isSocialPostAnnouncement(trimmed)) return;
  if (!VoiceOfficialJoin.isHomeBannerEntranceAnnouncement(trimmed) &&
      !VoiceOfficialJoin.isOfficialEntrance(trimmed) &&
      !_looksLikeSocialEntrance(trimmed)) {
    return;
  }

  final name = _parseDisplayName(trimmed);
  if (name == null || name.isEmpty) return;

  final eventId =
      'social:${trimmed.hashCode}:${DateTime.now().millisecondsSinceEpoch}';
  read(siteAnimationProvider(SiteAnimationContext.social.overlayId).notifier)
      .handleRoomEvent('user_joined', {
    'userId': 'social:$name',
    'name': name,
    'membership': _membershipFromBanner(trimmed),
    'eventId': eventId,
  });
}

/// Ana sayfa / global marquee giriş duyurusu → sosyal overlay kartı.
void dispatchSiteAnimationSocialEntranceRef(Ref ref, String bannerLine) =>
    _dispatchSiteAnimationSocialEntrance(ref.read, bannerLine);

void dispatchSiteAnimationSocialEntrance(WidgetRef ref, String bannerLine) =>
    _dispatchSiteAnimationSocialEntrance(ref.read, bannerLine);

bool _looksLikeSocialEntrance(String raw) {
  final lower = raw.toLowerCase();
  return lower.contains('sosyal paylaşımlara') ||
      lower.contains('sosyal paylasimlara') ||
      lower.contains('giriş yaptı') ||
      lower.contains('giris yapti');
}

String? _parseDisplayName(String raw) {
  var s = raw.replaceAll(RegExp(r'^[📣\s]+'), '').trim();
  s = s.replaceAll(
    RegExp(
      r'^(MODERATÖR|MODERATOR|MODERAT|ADMIN|YETKİLİ|YETKILI|STAFF|VIP|GOLD|DIAMOND|SVIP|KURUCU|FOUNDER|SOP)\s+',
      caseSensitive: false,
    ),
    '',
  );
  s = s.replaceAll(
    RegExp(
      r'\s+(sesli\s+)?od(a|ası)na\s+katıldı.*$',
      caseSensitive: false,
    ),
    '',
  );
  s = s.replaceAll(
    RegExp(r'\s+sosyal paylaşımlara giriş yaptı\.?$', caseSensitive: false),
    '',
  );
  s = s.replaceAll(
    RegExp(
      r'\s+sosyal alanda paylaşımda bulundu!?\.?$',
      caseSensitive: false,
    ),
    '',
  );
  s = s.replaceAll(
    RegExp(r'\s+canlı yayına katıldı\.?$', caseSensitive: false),
    '',
  );
  s = s.replaceAll(RegExp(r'\s+giriş yaptı\.?$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\s+joined.*$', caseSensitive: false), '');
  s = s
      .replaceFirst(RegExp(r'^[~&@%✨👑💎🌟🎤]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return s.isEmpty ? null : s;
}

String _membershipFromBanner(String raw) {
  final upper = raw.toUpperCase();
  if (upper.contains('SVIP') || upper.contains('EMPEROR')) return 'svip';
  if (upper.contains('DIAMOND') || upper.contains('💎')) return 'diamond';
  if (upper.contains(' VIP ') || upper.startsWith('VIP')) return 'vip';
  if (upper.contains(' GOLD ') || upper.startsWith('GOLD')) return 'gold';
  if (upper.contains('PREMIUM')) return 'premium';
  if (upper.contains('ADMIN') ||
      upper.contains('MODERAT') ||
      upper.contains('KURUCU') ||
      upper.contains('FOUNDER')) {
    return 'admin';
  }
  return SiteAnimationTier.normal.name;
}

/// Test için ayrıştırıcı.
@visibleForTesting
String? parseSocialEntranceDisplayNameForTest(String raw) => _parseDisplayName(raw);

@visibleForTesting
String membershipFromSocialBannerForTest(String raw) => _membershipFromBanner(raw);
