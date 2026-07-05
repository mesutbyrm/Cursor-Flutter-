import 'package:flutter/material.dart';

/// Gelen mesajların altında WhatsApp tarzı hızlı yanıtlar.
class ChatQuickRepliesBar extends StatelessWidget {
  const ChatQuickRepliesBar({
    super.key,
    required this.onSelect,
  });

  final ValueChanged<String> onSelect;

  static const _suggestions = [
    'Merhaba 👋',
    'Tamam',
    'Teşekkürler',
    'Sonra yazarım',
    '❤️',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final label = _suggestions[i];
          return ActionChip(
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1F2C34),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            onPressed: () => onSelect(label),
          );
        },
      ),
    );
  }
}
