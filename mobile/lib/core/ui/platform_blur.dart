import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Android'de [BackdropFilter] / [ImageFilter.blur] bazen tüm ekranı gri gösterir.
abstract final class PlatformBlur {
  static bool get supportsBackdropBlur => kIsWeb || !Platform.isAndroid;
}

/// Android'de blur kapalı — yetim gri tam ekran katmanı önlenir.
class SafeBackdropFilter extends StatelessWidget {
  const SafeBackdropFilter({
    super.key,
    required this.filter,
    required this.child,
    this.clipBehavior = Clip.hardEdge,
  });

  final ImageFilter filter;
  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (!PlatformBlur.supportsBackdropBlur) return child;
    return ClipRect(
      clipBehavior: clipBehavior,
      child: BackdropFilter(filter: filter, child: child),
    );
  }
}
