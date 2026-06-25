import 'dart:async';

import 'package:flutter/material.dart';

/// !temizle sonrası — yeşil saydam «Sohbet Temizlendi» 3 kez yanıp söner.
class VoiceChatClearedBanner extends StatefulWidget {
  const VoiceChatClearedBanner({super.key});

  @override
  State<VoiceChatClearedBanner> createState() => _VoiceChatClearedBannerState();
}

class _VoiceChatClearedBannerState extends State<VoiceChatClearedBanner> {
  static const _blinks = 3;
  var _visible = true;
  var _blinkOn = true;
  Timer? _timer;
  var _count = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
      if (!_blinkOn) {
        _count++;
        if (_count >= _blinks) {
          _timer?.cancel();
          setState(() => _visible = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _blinkOn ? 1 : 0.25,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.55),
          ),
        ),
        child: const Text(
          'Sohbet Temizlendi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
