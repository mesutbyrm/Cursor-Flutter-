import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Android'de [BackdropFilter] / [ImageFilter.blur] bazen tüm ekranı gri gösterir.
abstract final class PlatformBlur {
  static bool get supportsBackdropBlur => kIsWeb || !Platform.isAndroid;
}
