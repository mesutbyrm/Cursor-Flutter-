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
import 'voice_moderation_user_picker_sheet.dart';
import 'voice_youtube_song_sheet.dart';

/// Sağ «‹» — Oda Komutları paneli (canlifal.com).
Future<void> showVoiceRoomCommandsPanel(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  final container = ProviderScope.containerOf(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Oda Komutları',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
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
              child: UncontrolledProviderScope(
                container: container,
                child: _VoiceRoomCommandsPanel(
                  room: room,
                  perms: perms,
                  isOwner: isOwner,
                ),
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

  static const _musicGeneral = [
    _PromoCard(
      title: 'Şarkı İsteği',
      subtitle: "YouTube'dan şarkı iste (10 💎)",
      icon: Icons.music_note_rounded,
      color: Color(0xFF7B2FF7),
      kind: _PromoKind.songRequest,
    ),
    _PromoCard(
      title: 'Oda Kuralları',
      subtitle: 'Kuralları görüntüle',
      icon: Icons.shield_outlined,
      color: Color(0xFF38BDF8),
      kind: _PromoKind.rules,
    ),
    _PromoCard(
      title: 'Oda Bilgisi',
      subtitle: 'Oda detaylarını gör',
      icon: Icons.visibility_outlined,
      color: Color(0xFF38BDF8),
      kind: _PromoKind.info,
    ),
  ];

  static const _modGrid = [
    _PromoCard(
      title: 'Duyuru Yayınla',
      subtitle: '15 saniye sabit mesaj',
      icon: Icons.campaign_rounded,
      color: Color(0xFF3B82F6),
      kind: _PromoKind.duyuru,
    ),
    _PromoCard(
      title: 'Sohbet Temizle',
      subtitle: 'Tüm mesajları sil',
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFF22C55E),
      kind: _PromoKind.temizle,
    ),
    _PromoCard(
      title: 'Kick (At)',
      subtitle: '3 ihtar = otomatik ban',
      icon: Icons.back_hand_rounded,
      color: Color(0xFFEAB308),
      kind: _PromoKind.kick,
    ),
    _PromoCard(
      title: 'Banla',
      subtitle: 'Kullanıcıyı odadan banla',
      icon: Icons.block_rounded,
      color: AppThemeColors.liveRed,
      kind: _PromoKind.ban,
    ),
    _PromoCard(
      title: 'Ban Kaldır',
      subtitle: 'Banlanan kullanıcıları gör',
      icon: Icons.lock_open_rounded,
      color: Color(0xFF166534),
      kind: _PromoKind.unban,
    ),
    _PromoCard(
      title: 'Müzik Aç',
      subtitle: "YouTube'dan müzik çal/yönet",
      icon: Icons.library_music_rounded,
      color: Color(0xFF7B2FF7),
      kind: _PromoKind.musicHub,
    ),
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
        .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
        .fetchBannedWords();
    if (mounted) {
      setState(() {
        _words = words;
        _loadingWords = false;
      });
    }
  }

  Future<void> _runCommand(String cmd) async {
    final trimmed = cmd.trim();
    final notifier =
        ref.read(voiceRoomLiveProvider(widget.room.liveKey).notifier);
    if (trimmed.startsWith('!duyuru') || trimmed.startsWith('/duyuru')) {
      final message =
          trimmed.replaceFirst(RegExp(r'^[!/]duyuru\s*', caseSensitive: false), '').trim();
      if (message.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duyuru metni girin')),
        );
        return;
      }
      final err = await notifier.postModeratorAnnouncement(message);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      Navigator.pop(context);
      return;
    }
    if (trimmed == '!temizle' || trimmed == '/temizle') {
      final err = await notifier.clearChatAsModerator();
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      Navigator.pop(context);
      return;
    }
    await notifier.sendMessage(cmd);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onPromoTap(_PromoCard card) async {
    switch (card.kind) {
      case _PromoKind.songRequest:
        Navigator.pop(context);
        await showVoiceYoutubeSongSheet(context, ref, room: widget.room);
        return;
      case _PromoKind.rules:
        await _runCommand('!kural');
        return;
      case _PromoKind.info:
        await _runCommand('!bilgi');
        return;
      case _PromoKind.duyuru:
        await _onCommandTap(_Cmd('!duyuru', card.subtitle, card.icon, card.color));
        return;
      case _PromoKind.temizle:
        await _runCommand('!temizle');
        return;
      case _PromoKind.kick:
        await _onCommandTap(_Cmd('!kick', card.subtitle, card.icon, card.color));
        return;
      case _PromoKind.ban:
        await _onCommandTap(_Cmd('!ban', card.subtitle, card.icon, card.color));
        return;
      case _PromoKind.unban:
        await _onCommandTap(_Cmd('!unban', card.subtitle, card.icon, card.color));
        return;
      case _PromoKind.musicHub:
        Navigator.pop(context);
        await showVoiceMusicControlHub(
          context,
          ref,
          room: widget.room,
          perms: widget.perms,
          isOwner: widget.isOwner,
        );
        return;
    }
  }

  Future<void> _onCommandTap(_Cmd c) async {
    final cmd = c.command.trim();
    if (cmd == '!duyuru') {
      final message = await _promptDuyuru();
      if (message == null || !mounted) return;
      await _runCommand('!duyuru $message');
      return;
    }
    if (cmd == '!kick') {
      if (!widget.perms.canKickUsers && !widget.isOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kick yetkiniz yok')),
        );
        return;
      }
      final live = ref.read(voiceRoomLiveProvider(widget.room.liveKey));
      Navigator.pop(context);
      await showVoiceModerationUserPicker(
        context: context,
        ref: ref,
        room: widget.room,
        perms: widget.perms,
        action: VoiceModerationPickerAction.kick,
        presence: live.presence,
      );
      return;
    }
    if (cmd == '!ban') {
      if (!widget.perms.canBanUsers && !widget.isOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ban yetkiniz yok')),
        );
        return;
      }
      final live = ref.read(voiceRoomLiveProvider(widget.room.liveKey));
      Navigator.pop(context);
      await showVoiceModerationUserPicker(
        context: context,
        ref: ref,
        room: widget.room,
        perms: widget.perms,
        action: VoiceModerationPickerAction.ban,
        presence: live.presence,
      );
      return;
    }
    if (cmd == '!unban') {
      if (!widget.perms.canBanUsers && !widget.isOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ban kaldırma yetkiniz yok')),
        );
        return;
      }
      final live = ref.read(voiceRoomLiveProvider(widget.room.liveKey));
      Navigator.pop(context);
      await showVoiceModerationUserPicker(
        context: context,
        ref: ref,
        room: widget.room,
        perms: widget.perms,
        action: VoiceModerationPickerAction.unban,
        presence: live.presence,
      );
      return;
    }
    if (c.command.startsWith('!istek')) {
      final nav = Navigator.of(context);
      nav.pop();
      if (!mounted) return;
      await showVoiceYoutubeSongSheet(context, ref, room: widget.room);
      return;
    }
    if (c.command == '!yardım' || c.command == '!komutlar') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komutlar listesi yukarıda'),
          duration: Duration(milliseconds: 1500),
        ),
      );
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

  Future<String?> _promptDuyuru() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0E38),
        title: const Text('!duyuru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Duyuru metnini yazın…',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
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
        .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
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
        .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
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
    final coins = ref.watch(coinBalanceProvider) ?? 0;
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
                  icon: Icons.music_note_rounded,
                  title: 'MÜZİK & GENEL',
                  color: const Color(0xFF7B2FF7),
                ),
                ..._musicGeneral.map(
                  (c) => _PromoActionCard(card: c, onTap: () => _onPromoTap(c)),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  icon: Icons.shield_outlined,
                  title: 'YETKİLİ KOMUTLARI',
                  color: const Color(0xFF38BDF8),
                ),
                if (canModerate)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.55,
                    children: _modGrid
                        .map(
                          (c) => _PromoActionCard(
                            card: c,
                            compact: true,
                            onTap: () => _onPromoTap(c),
                          ),
                        )
                        .toList(),
                  )
                else
                  Text(
                    'Yetkili komutlar için moderasyon yetkisi gerekir.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
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

enum _PromoKind {
  songRequest,
  rules,
  info,
  duyuru,
  temizle,
  kick,
  ban,
  unban,
  musicHub,
}

class _PromoCard {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _PromoKind kind;
}

class _PromoActionCard extends StatelessWidget {
  const _PromoActionCard({
    required this.card,
    required this.onTap,
    this.compact = false,
  });

  final _PromoCard card;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 8),
      child: Material(
        color: card.color.withValues(alpha: compact ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: card.color.withValues(alpha: 0.45)),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(card.icon, color: card.color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        card.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(card.icon, color: card.color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
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
