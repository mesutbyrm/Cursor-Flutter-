import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import 'voice_room_hub_settings.dart';
import 'voice_youtube_song_sheet.dart';

/// Sağ kenar «‹» — kurallar, komutlar, jeton, yasaklı kelimeler.
Future<void> showVoiceRoomToolsSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VoiceRoomToolsSheet(
      room: room,
      perms: perms,
      isOwner: isOwner,
    ),
  );
}

class _VoiceRoomToolsSheet extends ConsumerWidget {
  const _VoiceRoomToolsSheet({
    required this.room,
    required this.perms,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final bool isOwner;

  static const _roomCommands = [
    ('/duyuru', 'Duyuru yayınla (moderatör)'),
    ('/temizle', 'Sohbeti temizle'),
    ('/muzik', 'Müzik / DJ bilgisi'),
  ];

  static const _staffCommands = [
    ('/kick @kullanıcı', 'Odadan çıkar (REST ban önerilir)'),
    ('/ban @kullanıcı', 'Yasakla'),
    ('/unban @kullanıcı', 'Yasağı kaldır'),
    ('/dj @kullanıcı', 'DJ ata / kaldır'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);
    final rules = (room.rulesTr ?? room.descTr ?? '').trim();
    final canModerate = perms.canModerate || isOwner;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ListView(
          controller: scroll,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Oda araçları',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _SectionTitle('Kanal kuralları'),
            _RulesBox(
              text: rules.isNotEmpty
                  ? rules
                  : 'Saygılı olun, spam yapmayın, reklam yasaktır. Yetkililerin uyarılarına uyun.',
            ),
            const SizedBox(height: 16),
            _SectionTitle('Oda komutları'),
            ..._roomCommands.map((c) => _CommandTile(command: c.$1, hint: c.$2)),
            const SizedBox(height: 12),
            _SectionTitle('Yetkili komutları'),
            ..._staffCommands.map((c) => _CommandTile(command: c.$1, hint: c.$2)),
            const SizedBox(height: 16),
            _SectionTitle('Jeton'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monetization_on_rounded, color: VoiceRoomTokens.gold),
              title: Text('Bakiye: $coinLabel jeton'),
              trailing: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  openJetonStore(context, ref: ref);
                },
                child: const Text('Jeton yükle'),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.music_note_rounded, color: VoiceRoomTokens.neonPurple),
              title: const Text('Şarkı isteği (ücretli)'),
              subtitle: const Text('Müzik veya sanatçı ara, sıraya ekle'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                showVoiceYoutubeSongSheet(context, ref, room: room);
              },
            ),
            if (canModerate) ...[
              const SizedBox(height: 16),
              _BannedWordsSection(room: room),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final live = ref.read(voiceRoomLiveProvider(room));
                showVoiceRoomHubSettingsSheet(
                  context,
                  ref,
                  room: room,
                  live: live,
                  perms: perms,
                  isOwner: isOwner,
                );
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Gelişmiş oda ayarları'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: context.colors.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _RulesBox extends StatelessWidget {
  const _RulesBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.command, required this.hint});

  final String command;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        command,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      subtitle: Text(hint, style: TextStyle(fontSize: 11, color: context.colors.onSurfaceMuted)),
      trailing: IconButton(
        icon: const Icon(Icons.copy_rounded, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: command));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$command kopyalandı')),
          );
        },
      ),
    );
  }
}

class _BannedWordsSection extends ConsumerStatefulWidget {
  const _BannedWordsSection({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_BannedWordsSection> createState() => _BannedWordsSectionState();
}

class _BannedWordsSectionState extends ConsumerState<_BannedWordsSection> {
  final _wordCtrl = TextEditingController();
  var _loading = true;
  List<String> _words = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final words = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .fetchBannedWords();
      if (mounted) setState(() => _words = words);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
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
    await _load();
  }

  Future<void> _remove(String word) async {
    final err = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .removeBannedWord(word);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Yasaklı kelimeler'),
        Text(
          'Bu kelimeler sohbette engellenir (oda moderatörleri).',
          style: TextStyle(fontSize: 11, color: context.colors.onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wordCtrl,
                decoration: InputDecoration(
                  hintText: 'Kelime ekle',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_words.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Henüz yasaklı kelime yok.',
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceMuted),
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
                    onDeleted: () => _remove(w),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
