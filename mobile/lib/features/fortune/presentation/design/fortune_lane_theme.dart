import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Fal bölümü tasarım gereği her temada koyu "mistik" zemin çizer (sayfalar
/// sabit `#0A0118` / `deepNight` kullanır). Açık temada içteki tema-duyarlı
/// bileşenler (kart, başlık, sekme, iskelet) açık renk alıp bu zeminle
/// çakışıyordu; bu kapsam onlara da koyu temayı verir. Koyu/AMOLED seçiminde
/// kullanıcının teması olduğu gibi kalır.
class FortuneLaneTheme extends StatelessWidget {
  const FortuneLaneTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return child;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(data: AppTheme.dark(), child: child),
    );
  }
}
