import 'package:flutter/material.dart';

import 'live_fortune_invite_action.dart';
import 'live_fortune_invite_sheet.dart';

/// Canlı fal kabul / beklet / red modalı — web ile aynı davranış.
Future<LiveFortuneInviteAction?> showFortuneRequestDialog(
  BuildContext context, {
  required String clientName,
  required String category,
  required int durationMinutes,
  required int totalJeton,
  String? clientAvatarUrl,
}) =>
    showLiveFortuneTellerInviteSheet(
      context,
      clientName: clientName,
      category: category,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
      clientAvatarUrl: clientAvatarUrl,
    );
