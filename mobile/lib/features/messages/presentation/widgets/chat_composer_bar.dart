import 'package:flutter/material.dart';

import 'chat_composer.dart';

/// Gönderim durumu yalnızca composer satırını yeniler.
class ChatComposerBar extends StatefulWidget {
  const ChatComposerBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
  });

  final TextEditingController controller;
  final Future<void> Function(String text) onSend;
  final ValueChanged<String>? onChanged;

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  var _sending = false;

  Future<void> _handleSend() async {
    final t = widget.controller.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(t);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatComposer(
      controller: widget.controller,
      sending: _sending,
      onSend: _handleSend,
      onChanged: widget.onChanged,
    );
  }
}
