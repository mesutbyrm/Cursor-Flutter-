import 'package:flutter/material.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_mention.dart';
import 'voice_room_mention_suggestions.dart';

/// Faz 11 — @ etiket destekli sohbet girişi.
class VoiceRoomMentionTextField extends StatefulWidget {
  const VoiceRoomMentionTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.presence,
    this.excludeUserId,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Mesajınızı yazın...',
    this.style,
    this.decoration,
    this.minLines = 1,
    this.maxLines = 3,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<ChatRoomPresence> presence;
  final String? excludeUserId;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int minLines;
  final int maxLines;

  @override
  State<VoiceRoomMentionTextField> createState() =>
      _VoiceRoomMentionTextFieldState();
}

class _VoiceRoomMentionTextFieldState extends State<VoiceRoomMentionTextField> {
  VoiceRoomMentionQuery? _trigger;
  List<ChatRoomPresence> _suggestions = const [];

  void _refreshMentions() {
    final query = VoiceRoomMention.detectQuery(
      widget.controller.text,
      widget.controller.selection,
    );
    if (query == null) {
      if (_trigger != null) {
        setState(() {
          _trigger = null;
          _suggestions = const [];
        });
      }
      return;
    }
    final next = VoiceRoomMention.filterSuggestions(
      presence: widget.presence,
      query: query.query,
      excludeUserId: widget.excludeUserId,
    );
    setState(() {
      _trigger = query;
      _suggestions = next;
    });
  }

  void _handleChanged(String value) {
    _refreshMentions();
    widget.onChanged?.call(value);
  }

  void _pickUser(ChatRoomPresence user) {
    final trigger = _trigger;
    if (trigger == null) return;
    VoiceRoomMention.insertMention(
      controller: widget.controller,
      handle: VoiceRoomMention.handleFor(user),
      trigger: trigger,
    );
    setState(() {
      _trigger = null;
      _suggestions = const [];
    });
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_trigger != null && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: VoiceRoomMentionSuggestions(
              users: _suggestions,
              onPick: _pickUser,
            ),
          ),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _handleChanged,
          onTap: _refreshMentions,
          style: widget.style ??
              const TextStyle(fontSize: 14, color: Colors.white),
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          textInputAction: TextInputAction.send,
          onSubmitted: widget.onSubmitted,
          decoration: widget.decoration ??
              InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: VoiceRoomTokens.neonPurple,
                    width: 1.2,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
