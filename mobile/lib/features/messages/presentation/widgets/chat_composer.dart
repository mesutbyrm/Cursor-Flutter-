import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Ek menüsü eylemleri. DM API'si yalnızca metin taşır; bu yüzden yalnızca
/// niyet/davet mesajları var. Fotoğraf, video, dosya, konum, GIF ve sticker
/// seçenekleri hiçbir şey seçtirmeden "GIF gönderdi" gibi metin yolluyordu →
/// kaldırıldı.
enum DmComposerAction {
  gift,
  jeton,
  fortune,
  voiceFortune,
  videoFortune,
  liveInvite,
  voiceRoomInvite,
}

class ChatComposer extends ConsumerWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.sending,
    this.onChanged,
    this.onAction,
    this.onVoiceNote,
    this.tightBottomInset = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final ValueChanged<String>? onChanged;
  final ValueChanged<DmComposerAction>? onAction;
  final VoidCallback? onVoiceNote;

  /// Sohbet tam ekran (/chat) — alt navbar yokken fazla boşluk bırakma.
  final bool tightBottomInset;

  void _showEmojiPicker(BuildContext context) {
    const emojis = [
      '😀',
      '😂',
      '❤️',
      '🔥',
      '👏',
      '🎉',
      '💎',
      '🙏',
      '✨',
      '😍',
      '🤣',
      '👋',
      '🌙',
      '⭐',
      '😊',
      '💜',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: emojis
              .map(
                (e) => InkWell(
                  onTap: () {
                    controller.text = '${controller.text}$e';
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                    Navigator.pop(sheet);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      minimum: tightBottomInset
          ? const EdgeInsets.only(bottom: 4)
          : EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, tightBottomInset ? 6 : 12),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Emoji seç',
              child: IconButton(
                tooltip: 'Emoji',
                onPressed: () => _showEmojiPicker(context),
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                textField: true,
                label: 'Mesaj yazın',
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mesaj yazın',
                    hintStyle: TextStyle(
                      color: context.colors.onSurfaceMuted.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    filled: true,
                    fillColor: context.colors.glassFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: AppThemeColors.accentPurple.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: AppThemeColors.accentPurple.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppThemeColors.accentPink,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Mesaj gönder',
              enabled: !sending,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: sending ? null : onSend,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: context.colors.brandGradient,
                    ),
                    child: Center(
                      child: sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
