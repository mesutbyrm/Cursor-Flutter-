import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_composer.dart';

/// Gönderim durumu yalnızca composer satırını yeniler.
class ChatComposerBar extends StatefulWidget {
  const ChatComposerBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
    this.onAction,
    this.onVoiceNote,
    this.tightBottomInset = false,
  });

  final TextEditingController controller;
  final Future<void> Function(String text) onSend;
  final ValueChanged<String>? onChanged;
  final ValueChanged<DmComposerAction>? onAction;
  final VoidCallback? onVoiceNote;
  final bool tightBottomInset;

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  var _sending = false;

  Future<void> _handleSend() async {
    final t = widget.controller.text.trim();
    if (t.isEmpty || _sending) return;
    // Gönderim arka planda sürer; yeni mesaj yazmak engellenmez.
    unawaited(widget.onSend(t));
  }

  @override
  Widget build(BuildContext context) {
    return ChatComposer(
      controller: widget.controller,
      sending: _sending,
      onSend: _handleSend,
      onChanged: widget.onChanged,
      onAction: widget.onAction,
      onVoiceNote: widget.onVoiceNote,
      tightBottomInset: widget.tightBottomInset,
    );
  }
}
