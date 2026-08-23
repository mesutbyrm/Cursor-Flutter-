import 'package:flutter/material.dart';
import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

enum DmComposerAction {
  photo,
  video,
  file,
  location,
  gift,
  jeton,
  fortune,
  voiceFortune,
  videoFortune,
  liveInvite,
  voiceRoomInvite,
  gif,
  sticker,
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.sending,
    this.onChanged,
    this.onAction,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final ValueChanged<String>? onChanged;
  final ValueChanged<DmComposerAction>? onAction;

  void _showEmojiPicker(BuildContext context) {
    const emojis = [
      '😀', '😂', '❤️', '🔥', '👏', '🎉', '💎', '🙏',
      '✨', '😍', '🤣', '👋', '🌙', '⭐', '😊', '💜',
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

  void _showActionSheet(BuildContext context) {
    final actions = [
      (DmComposerAction.photo, Icons.photo_rounded, 'Fotoğraf', AppThemeColors.accentCyan),
      (DmComposerAction.video, Icons.videocam_rounded, 'Video', AppThemeColors.liveRed),
      (DmComposerAction.file, Icons.attach_file_rounded, 'Dosya', Colors.white70),
      (DmComposerAction.location, Icons.location_on_rounded, 'Konum', Colors.greenAccent),
      (DmComposerAction.gift, Icons.card_giftcard_rounded, 'Hediye', AppThemeColors.coinGold),
      (DmComposerAction.jeton, Icons.toll_rounded, 'Jeton', AppThemeColors.coinGold),
      (DmComposerAction.fortune, Icons.auto_awesome_rounded, 'Fal İste', AppThemeColors.accentPurple),
      (DmComposerAction.voiceFortune, Icons.mic_rounded, 'Sesli Fal', AppThemeColors.accentPink),
      (DmComposerAction.videoFortune, Icons.video_call_rounded, 'Görüntülü Fal', Colors.cyanAccent),
      (DmComposerAction.liveInvite, Icons.podcasts_rounded, 'Canlı Yayın', AppThemeColors.liveRed),
      (DmComposerAction.voiceRoomInvite, Icons.groups_rounded, 'Sesli Oda', AppThemeColors.accentCyan),
      (DmComposerAction.gif, Icons.gif_box_rounded, 'GIF', Colors.purpleAccent),
      (DmComposerAction.sticker, Icons.emoji_emotions_rounded, 'Sticker', Colors.orangeAccent),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheet) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.32),
            ),
            boxShadow: AppThemeColors.glowShadow(
              AppThemeColors.accentPurple,
              blur: 24,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 4;
              const spacing = 10.0;
              const aspect = 0.92;
              final gridHeight = ListPerf.nestedGridHeight(
                itemCount: actions.length,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspect,
                crossAxisExtent: constraints.maxWidth,
              );
              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspect,
                  ),
                  itemCount: actions.length,
                  itemBuilder: (context, i) {
                    final a = actions[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(sheet);
                        onAction?.call(a.$1);
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    a.$4.withValues(alpha: 0.95),
                                    AppThemeColors.accentPurple.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                              child: Icon(a.$2, color: Colors.white, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a.$3,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showActionSheet(context),
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppThemeColors.accentPurple.withValues(alpha: 0.9),
              ),
            ),
            IconButton(
              onPressed: () => _showEmojiPicker(context),
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.white70,
              ),
            ),
            Expanded(
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
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppThemeColors.accentPink),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => onAction?.call(DmComposerAction.voiceFortune),
              style: IconButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple.withValues(alpha: 0.72),
              ),
              icon: const Icon(Icons.mic_rounded, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Material(
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
          ],
        ),
      ),
    );
  }
}
