import 'package:flutter/material.dart';

import '../../domain/entities/fortune_type_entity.dart';
import '../services/fortune_result_speech.dart';

/// Fal sonucu altında — metni sesli okur.
class FortuneListenButton extends StatefulWidget {
  const FortuneListenButton({
    super.key,
    required this.result,
  });

  final FortuneReadingResult result;

  @override
  State<FortuneListenButton> createState() => _FortuneListenButtonState();
}

class _FortuneListenButtonState extends State<FortuneListenButton> {
  var _speaking = false;

  Future<void> _toggle() async {
    if (_speaking) {
      await FortuneResultSpeech.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await FortuneResultSpeech.speak(widget.result);
    if (mounted) setState(() => _speaking = FortuneResultSpeech.isSpeaking);
  }

  @override
  void dispose() {
    if (_speaking) {
      FortuneResultSpeech.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.result.type.accent;

    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(_speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
      label: Text(_speaking ? 'Durdur' : 'Sesli dinle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: accent.withValues(alpha: 0.65)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
