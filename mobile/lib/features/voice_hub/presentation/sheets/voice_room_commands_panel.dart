import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import 'voice_youtube_song_sheet.dart';

/// Sağ «‹» — Oda Komutları paneli (canlifal.com).
Future<void> showVoiceRoomCommandsPanel(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Oda Komutları',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      final w = MediaQuery.sizeOf(ctx).width;
      return SlideTransition(
        position: slide,
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: const Color(0xFF12082A),
            child: SizedBox(
              width: (w * 0.92).clamp(300.0, 420.0),
              height: MediaQuery.sizeOf(ctx).height,
              child: _VoiceRoomCommandsPanel(
                room: room,
                perms: perms,
                isOwner: isOwner,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _VoiceRoomCommandsPanel extends ConsumerStatefulWidget {
  const _VoiceRoomCommandsPanel({
    required this.room,
    required this.perms,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final bool isOwner;

  @override
  ConsumerState<_VoiceRoomCommandsPanel> createState() =>
      _VoiceRoomCommandsPanelState();
}

class _VoiceRoomCommandsPanelState extends ConsumerState<_VoiceRoomCommandsPanel> {
  final _wordCtrl = TextEditingController();
  var _loadingWords = true;
  List<String> _words = const [];

  static const _everyone = [
    _Cmd('!istek şarkı adı', 'Şarkı isteği gönderir (yetkililere görünür)', Icons.music_note_rounded),
    _Cmd('!kural', 'Oda kurallarını gösterir', Icons.article_outlined),
    _Cmd('!bilgi', 'Oda bilgilerini gösterir', Icons.info_outline_rounded),
    _Cmd('!yardım', 'Bu paneli açar', Icons.menu_book_outlined),
  ];

  static const _staff = [
    _Cmd('!ban kullanıcı', 'Kullanıcıyı odadan banlar', Icons.block_rounded, AppThemeColors.liveRed),
    _Cmd('!sessiz kullanıcı', '30 dakika susturur', Icons.volume_off_rounded, AppThemeColors.liveRed),
    _Cmd('!at kullanıcı', 'Kullanıcıyı odadan atar', Icons.back_hand_rounded, Color(0xFFB8860B)),
    _Cmd('!temizle', 'Tüm sohbeti temizler', Icons.auto_fix_high_rounded, VoiceRoomTokens.gold),
    _Cmd('!duyuru mesaj', 'Duyuru mesajı yayınlar', Icons.campaign_rounded, AppThemeColors.liveRed),
    _Cmd('!yetki kullanıcı sembol', 'Rol verir', Icons.verified_rounded, Color(0xFF22C55E)),
  ];

  static const _roleTags = [
    ('~', 'Founder', Color(0xFFFFD700)),
    ('%', 'SuperAdmin', Color(0xFFFF4FD8)),
    ('&', 'SOP', Color(0xFFFF6B35)),
    ('@', 'OP', Color(0xFF25F4EE)),
    ('+', 'Voice', Color(0xFF3B82F6)),
  ];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() => _loadingWords = true);
    final words = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .fetchBannedWords();
    if (mounted) {
      setState(() {
        _words = words;
        _loadingWords = false;
      });
    }
  }

  Future<void> _runCommand(String cmd) async {
    await ref.read(voiceRoomLiveProvider(widget.room).notifier).sendMessage(cmd);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onCommandTap(_Cmd c) async {
    if (c.command.startsWith('!istek')) {
      final nav = Navigator.of(context);
      nav.pop();
      if (!mounted) return;
      await showVoiceYoutubeSongSheet(context, ref, room: widget.room);
      return;
    }
    if (c.command == '!yardım') {
      await _runCommand('!yardım');
      return;
    }
    final needsArgs = c.command.contains('kullanıcı') ||
        c.command.contains('mesaj') ||
        c.command.contains('sembol');
    if (needsArgs) {
      final filled = await _promptCommandArgs(c.command);
      if (filled == null || !mounted) return;
      await _runCommand(filled);
      return;
    }
    await _runCommand(c.command.split(' ').first);
  }

  Future<String?> _promptCommandArgs(String template) async {
    final ctrl = TextEditingController(text: template);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0E38),
        title: const Text('Komutu düzenle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Örn. !ban kullanici',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _addWord() async {
    final w = _wordCtrl.text.trim();
    if (w.isEmpty) return;
    final err = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .addBannedWord(w);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _wordCtrl.clear();
    await _loadWords();
  }

  Future<void> _removeWord(String w) async {
    final err = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .removeBannedWord(w);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);
    final canModerate = widget.perms.canModerate || widget.isOwner;
    final top = MediaQuery.paddingOf(context).top;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 4, 8, 8),
            child: Row(
              children: [
                Icon(Icons.settings_rounded, color: VoiceRoomTokens.gold, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Oda Komutları',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: VoiceRoomTokens.gold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                _SectionHeader(
                  icon: Icons.person_outline_rounded,
                  title: 'HERKES',
                  color: const Color(0xFF38BDF8),
                ),
                ..._everyone.map(
                  (c) => _CommandCard(cmd: c, onTap: () => _onCommandTap(c)),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  icon: Icons.shield_outlined,
                  title: 'YETKİLİ KOMUTLARI',
                  color: const Color(0xFF38BDF8),
                ),
                ..._staff.map(
                  (c) => _CommandCard(cmd: c, onTap: () => _onCommandTap(c)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _roleTags
                      .map(
                        (t) => Chip(
                          label: Text('${t.$1} ${t.$2}'),
                          backgroundColor: t.$3.withValues(alpha: 0.2),
                          side: BorderSide(color: t.$3.withValues(alpha: 0.5)),
                          labelStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: t.$3,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                _JetonCard(
                  balance: coinLabel,
                  onTopUp: () {
                    final ctx = context;
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!ctx.mounted) return;
                      openJetonStore(ctx, ref: ref);
                    });
                  },
                ),
                if (canModerate) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.block_rounded,
                    title: 'YASAKLI KELİMELER',
                    color: AppThemeColors.liveRed,
                  ),
                  Text(
                    'Bu kelimeleri içeren mesajlar moderatörlere bildirilir.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wordCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Yasaklı kelime ekle...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _addWord(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addWord,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppThemeColors.liveRed,
                        ),
                        child: const Text('Ekle'),
                      ),
                    ],
                  ),
                  if (_loadingWords)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _words
                          .map(
                            (w) => InputChip(
                              label: Text(w),
                              onDeleted: () => _removeWord(w),
                              deleteIconColor: Colors.white70,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cmd {
  const _Cmd(this.command, this.hint, this.icon, [this.iconColor]);

  final String command;
  final String hint;
  final IconData icon;
  final Color? iconColor;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.cmd, required this.onTap});

  final _Cmd cmd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF2A1548).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(cmd.icon, size: 22, color: cmd.iconColor ?? Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cmd.command,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: VoiceRoomTokens.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cmd.hint,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: Colors.white38,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cmd.command));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Komut kopyalandı')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JetonCard extends StatelessWidget {
  const _JetonCard({required this.balance, required this.onTopUp});

  final String balance;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1548).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: VoiceRoomTokens.gold.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              const Text(
                'Jeton Bakiye',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond_rounded, color: VoiceRoomTokens.gold, size: 28),
              const SizedBox(width: 8),
              Text(
                balance,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onTopUp,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Jeton Yükle'),
            style: FilledButton.styleFrom(
              backgroundColor: VoiceRoomTokens.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
