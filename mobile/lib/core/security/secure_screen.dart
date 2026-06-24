import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android FLAG_SECURE — ekran görüntüsü / son uygulamalar önizlemesinde şifre gizlenir.
abstract final class SecureScreenController {
  static const _channel = MethodChannel('com.mesutbyrm.canlifal/security');

  static var _depth = 0;

  static Future<void> enable() async {
    if (kIsWeb) return;
    _depth++;
    if (_depth != 1) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': true});
    } catch (_) {}
  }

  static Future<void> disable() async {
    if (kIsWeb) return;
    if (_depth <= 0) return;
    _depth--;
    if (_depth != 0) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': false});
    } catch (_) {}
  }
}

/// Şifre giriş ekranlarında kullanın — dispose'da güvenli mod kapanır.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    SecureScreenController.enable();
  }

  @override
  void dispose() {
    SecureScreenController.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
