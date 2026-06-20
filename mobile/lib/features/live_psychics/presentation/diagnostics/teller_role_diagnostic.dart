import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../data/services/fortune_teller_profile_resolver.dart';
import '../../domain/entities/psychic_entity.dart';

/// Falcı rolü çözümlemesi — debug log (üretimde de sorun teşhisi için).
class TellerRoleDiagnostic {
  TellerRoleDiagnostic({
    required this.authUserId,
    required this.role,
    required this.profileFound,
    required this.fortuneTellerId,
    required this.isUsable,
    required this.isApprovedTeller,
    required this.isFortuneTeller,
    required this.resolveSource,
    this.approvalStatus,
    this.onlineStatus,
    this.blockReason,
    this.rawMyProfile,
    this.rawMeSnippet,
  });

  final String? authUserId;
  final String? role;
  final bool profileFound;
  final String? fortuneTellerId;
  final bool isUsable;
  final bool isApprovedTeller;
  final bool isFortuneTeller;
  final String resolveSource;
  final String? approvalStatus;
  final bool? onlineStatus;
  final String? blockReason;
  final String? rawMyProfile;
  final String? rawMeSnippet;

  void emit() {
    debugPrint(
      '[TellerDebug]\n'
      'profileFound=$profileFound\n'
      'fortuneTellerId=${fortuneTellerId ?? ""}\n'
      'authUserId=${authUserId ?? ""}\n'
      'isUsable=$isUsable\n'
      'isApprovedTeller=$isApprovedTeller\n'
      'isFortuneTeller=$isFortuneTeller\n'
      'resolveSource=$resolveSource',
    );
  }

  static TellerRoleDiagnostic fromResolve({
    required UserEntity user,
    required FortuneTellerProfileResult resolved,
  }) {
    final profile = resolved.profile;
    final found = resolved.profileFound;
    final usable = resolved.isUsable;
    return TellerRoleDiagnostic(
      authUserId: user.id,
      role: user.role,
      profileFound: found,
      fortuneTellerId: profile?.id,
      isUsable: usable,
      isApprovedTeller: usable,
      isFortuneTeller: usable,
      resolveSource: resolved.source,
      approvalStatus: profile?.applicationStatus,
      onlineStatus: profile?.isOnline,
      blockReason: found && usable
          ? ''
          : _blockReason(resolved),
      rawMyProfile: resolved.rawMyProfile,
      rawMeSnippet: resolved.rawMeSnippet,
    );
  }

  static String _blockReason(FortuneTellerProfileResult resolved) {
    if (resolved.source == 'no_auth_user') {
      return 'Oturum kullanıcı kimliği boş';
    }
    return 'my-profile, fortune-tellers listesi (userId=${resolved.authUserId}) '
        've /api/me ile falcı profili çözülemedi; '
        'authUser.id fortuneTeller.id ile karıştırılmamalı';
  }

  static TellerRoleDiagnostic from({
    required UserEntity user,
    required PsychicEntity? profile,
    required String resolveSource,
    String? rawMyProfile,
    String? rawMeSnippet,
  }) {
    final usable = profile?.isUsable == true;
    return TellerRoleDiagnostic(
      authUserId: user.id,
      role: user.role,
      profileFound: profile != null,
      fortuneTellerId: profile?.id,
      isUsable: usable,
      isApprovedTeller: usable,
      isFortuneTeller: usable,
      resolveSource: resolveSource,
      approvalStatus: profile?.applicationStatus,
      onlineStatus: profile?.isOnline,
      blockReason: usable ? '' : 'Profil bulunamadı veya kullanılamaz',
      rawMyProfile: rawMyProfile,
      rawMeSnippet: rawMeSnippet,
    );
  }

  static String truncateJson(dynamic body, {int max = 600}) {
    if (body == null) return 'null';
    try {
      final text = body is String ? body : jsonEncode(body);
      if (text.length <= max) return text;
      return '${text.substring(0, max)}…';
    } catch (_) {
      return body.toString();
    }
  }
}

/// Geriye dönük — [RolePanelResolver] delegasyonu.
class TellerResolveResult {
  const TellerResolveResult({
    this.profile,
    this.source = 'none',
    this.rawMyProfile,
    this.rawMeSnippet,
  });

  final PsychicEntity? profile;
  final String source;
  final String? rawMyProfile;
  final String? rawMeSnippet;
}
