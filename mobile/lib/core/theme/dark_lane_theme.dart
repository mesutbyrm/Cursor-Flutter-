import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Tasarım gereği her temada koyu zemin çizen bölümler (fal, sesli oda) için
/// koyu tema kapsamı.
///
/// Bu sayfalar sabit koyu zemin kullanır; açık temada içteki tema-duyarlı
/// bileşenler (kart, başlık, sekme, iskelet, alt sayfa) açık tema renklerini
/// alıp zeminle çakışıyordu. Koyu/AMOLED seçiminde kullanıcının teması olduğu
/// gibi kalır.
class DarkLaneTheme extends StatelessWidget {
  const DarkLaneTheme({super.key, required this.child});

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
