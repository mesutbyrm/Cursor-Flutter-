import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// DM sesli görüşme — yalnızca ses (Gold), Tencent TRTC.
class DmVoiceCallPage extends ConsumerStatefulWidget {
  const DmVoiceCallPage({
    super.key,
    required this.peerName,
    required this.channelId,
  });

  final String peerName;
  final String channelId;

  @override
  ConsumerState<DmVoiceCallPage> createState() => _DmVoiceCallPageState();
}

class _DmVoiceCallPageState extends ConsumerState<DmVoiceCallPage> {
  final _trtc = TrtcRoomManager();
  var _ready = false;
  var _muted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    try {
      final cred = await ref.read(trtcRemoteProvider).fetchToken(
            roomId: widget.channelId,
            role: 'host',
          );
      await _trtc.join(credentials: cred, isHost: true, audioOnly: true);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama başlatılamadı: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_trtc.leave());
    _trtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.call_rounded, color: Color(0xFF25D366), size: 48),
            const SizedBox(height: 16),
            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ready ? 'Sesli görüşme devam ediyor' : 'Bağlanılıyor…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: const Color(0xFF1F2C34),
                  onPressed: () {
                    _muted = !_muted;
                    _trtc.setMicEnabled(!_muted);
                    setState(() {});
                  },
                  child: Icon(_muted ? Icons.mic_off_rounded : Icons.mic_rounded),
                ),
                FloatingActionButton(
                  heroTag: 'end',
                  backgroundColor: const Color(0xFFE53935),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.call_end_rounded),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
