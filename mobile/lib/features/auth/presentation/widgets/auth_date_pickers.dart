import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

/// Kayıt formu — Material yerelleştirme ile tarih/saat seçici.
Future<DateTime?> showAuthBirthDatePicker(
  BuildContext context, {
  DateTime? initial,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(now.year - 25, now.month, now.day),
    firstDate: DateTime(1920),
    lastDate: now,
    locale: const Locale('tr', 'TR'),
    helpText: 'Doğum tarihi',
    cancelText: 'İptal',
    confirmText: 'Tamam',
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.accentPink,
            onPrimary: Colors.white,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: theme.dialogTheme.copyWith(
            backgroundColor: AppColors.bgPurpleGlow,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

Future<TimeOfDay?> showAuthBirthTimePicker(
  BuildContext context, {
  TimeOfDay? initial,
}) {
  return showTimePicker(
    context: context,
    initialTime: initial ?? const TimeOfDay(hour: 12, minute: 0),
    helpText: 'Doğum saati',
    cancelText: 'İptal',
    confirmText: 'Tamam',
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.accentCyan,
            onPrimary: Colors.black,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: theme.dialogTheme.copyWith(
            backgroundColor: AppColors.bgPurpleGlow,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

String formatBirthDate(DateTime date) =>
    DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
