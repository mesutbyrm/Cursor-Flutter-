import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Türkçe tarih/saat seçicileri için gerekli delegeler.
abstract final class AppLocalizationsConfig {
  static const locale = Locale('tr', 'TR');

  static const supportedLocales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
  ];

  static const delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
