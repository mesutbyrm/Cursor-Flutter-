import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/psychic_entity.dart';

/// Falcı rolü çözümlemesi — debug log (üretimde de sorun teşhisi için).
class TellerRoleDiagnostic {
  TellerRoleDiagnostic({
    required this.userId,
    required this.role,
    required this.isFortuneTeller,
    required this.tellerId,
    required this.tellerProfileFound,
    required this.onlineStatus,
    required this.approvalStatus,
    required this.resolveSource,
    this.rawMyProfile,
    this.rawMeSnippet,
  });

  final String? userId;
  final String? role;
  final bool isFortuneTeller;
  final String? tellerId;
  final bool tellerProfileFound;
  final bool? onlineStatus;
  final String? approvalStatus;
  final String resolveSource;
  final String? rawMyProfile;
  final String? rawMeSnippet;

  void emit() {
    final payload = {
      'userId': userId,
      'role': role,
      'isFortuneTeller': isFortuneTeller,
      'tellerId': tellerId,
      'tellerProfile': tellerProfileFound,
      'onlineStatus': onlineStatus,
      'approvalStatus': approvalStatus,
      'resolveSource': resolveSource,
      if (rawMyProfile != null) 'rawMyProfile': rawMyProfile,
      if (rawMeSnippet != null) 'rawMe': rawMeSnippet,
    };
    debugPrint('[TellerRole] ${jsonEncode(payload)}');
  }

  static TellerRoleDiagnostic from({
    required UserEntity user,
    required PsychicEntity? profile,
    required String resolveSource,
    String? rawMyProfile,
    String? rawMeSnippet,
  }) {
    return TellerRoleDiagnostic(
      userId: user.id,
      role: user.role,
      isFortuneTeller: profile?.isUsable == true,
      tellerId: profile?.id,
      tellerProfileFound: profile != null,
      onlineStatus: profile?.isOnline,
      approvalStatus: profile?.applicationStatus,
      resolveSource: resolveSource,
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
