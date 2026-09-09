import 'dart:async';

import 'package:flutter/material.dart';

/// İzleyici — yayıncı bağlantısı koptuğunda kalıcı bilgi bandı + geri sayım.
class LiveHostAwayViewerBanner extends StatefulWidget {
  const LiveHostAwayViewerBanner({
    super.key,
    this.graceEndsAt,
    this.graceMinutes = 5,
  });

  final DateTime? graceEndsAt;
  final int graceMinutes;

  @override
  State<LiveHostAwayViewerBanner> createState() =>
      _LiveHostAwayViewerBannerState();
}

class _LiveHostAwayViewerBannerState extends State<LiveHostAwayViewerBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final endsAt = widget.graceEndsAt ??
        DateTime.now().add(Duration(minutes: widget.graceMinutes));
    final left = endsAt.difference(DateTime.now());
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 96,
      left: 16,
      right: 16,
      child: Material(
        color: const Color(0xFF2A1545).withValues(alpha: 0.94),
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFB74D), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _remaining > Duration.zero
                      ? 'Yayıncının bağlantısı koptu. Yayın ${_format(_remaining)} içinde kapanabilir — geri döndüğünde devam edecek.'
                      : 'Yayıncı bağlantısı bekleniyor…',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
