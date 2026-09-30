import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../domain/utils/dm_message_codec.dart';

class DmVoiceNoteBubble extends StatefulWidget {
  const DmVoiceNoteBubble({super.key, required this.meta});

  final DmVoiceNoteMeta meta;

  @override
  State<DmVoiceNoteBubble> createState() => _DmVoiceNoteBubbleState();
}

class _DmVoiceNoteBubbleState extends State<DmVoiceNoteBubble> {
  final _player = AudioPlayer();
  var _playing = false;

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(widget.meta.url));
    if (mounted) setState(() => _playing = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (DmMessageCodec.isExpiredVoiceNote(widget.meta)) {
      return Text(
        'Sesli mesaj süresi doldu (24 saat)',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 8),
          const Text(
            'Sesli mesaj',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
