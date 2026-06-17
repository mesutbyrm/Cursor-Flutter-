import 'package:flutter/material.dart';

import 'live_fortune_invite_sheet.dart';

/// Canlı fal kabul/red modalı — web ile aynı davranış.
Future<bool?> showFortuneRequestDialog(
  BuildContext context, {
  required String clientName,
  required String category,
  required int durationMinutes,
  required int totalJeton,
}) =>
    showLiveFortuneTellerInviteSheet(
      context,
      clientName: clientName,
      category: category,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
    );
