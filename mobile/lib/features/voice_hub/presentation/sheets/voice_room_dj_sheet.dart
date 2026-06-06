import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_neon_avatar.dart';

Future<void> showVoiceRoomDjSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => _DjDialog(
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
    ),
  );
}

class _DjDialog extends ConsumerStatefulWidget {
  const _DjDialog({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;

  @override
  ConsumerState<_DjDialog> createState() => _DjDialogState();
}

class _DjDialogState extends ConsumerState<_DjDialog> {
  var _busy = false;

  Set<String> get _djIds =>
      widget.live.dj.djUsers.map((u) => u.id).toSet();

  List<ChatRoomPresence> get _djUsers {
    return widget.live.presence.where((p) => _djIds.contains(p.id)).toList();
  }

  List<ChatRoomPresence> get _eligible {
    final djIds = _djIds;
    final ownerId = widget.room.ownerId;
    return widget.live.presence.where((p) {
      if (djIds.contains(p.id)) return false;
      if (ownerId != null && p.id == ownerId) return false;
      return true;
    }).toList();
  }

  bool get _canManage => widget.isOwner || widget.perms.canManageDj;

  Future<void> _toggleDj(ChatRoomPresence user, bool add) async {
    if (!_canManage || _busy) return;
    setState(() => _busy = true);
    final ctrl = ref.read(voiceRoomLiveProvider(widget.room).notifier);
    final err = add
        ? await ctrl.addRoomDj(user.id)
        : await ctrl.removeRoomDj(user.id);
    if (mounted) setState(() => _busy = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickDj() async {
    final eligible = _eligible;
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eklenebilecek kullanıcı yok')),
      );
      return;
    }
    final picked = await showModalBottomSheet<ChatRoomPresence>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'DJ olarak ekle',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            ...eligible.map(
              (p) => ListTile(
                leading: VoiceNeonAvatar(url: p.image, size: 40),
                title: Text(p.displayName),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) await _toggleDj(picked, true);
  }

  @override
  Widget build(BuildContext context) {
    final djCount = widget.live.dj.djCount;
    final ownerInRoom = widget.room.ownerId != null &&
        widget.live.presence.any((p) => p.id == widget.room.ownerId);

    return Dialog(
      backgroundColor: const Color(0xFF1A0E38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.headphones_rounded, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DJ Yönetimi ($djCount/5)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.5)),
                  color: VoiceRoomTokens.gold.withValues(alpha: 0.08),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👑 Oda Sahibi Kuralları',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: VoiceRoomTokens.gold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Oda sahibi her zaman müzik çalabilir\n'
                      '• Oda sahibi odadayken DJ\'ler sadece izin verilince çalar\n'
                      '• Oda sahibi yokken sıralamaya göre öncelik belirlenir',
                      style: TextStyle(fontSize: 11, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_djUsers.isEmpty)
                Text(
                  'Henüz DJ eklenmedi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
              else
                ..._djUsers.map(
                  (u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: VoiceNeonAvatar(url: u.image, size: 36),
                    title: Text(u.displayName, style: const TextStyle(fontSize: 13)),
                    trailing: _canManage
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppThemeColors.liveRed),
                            onPressed: _busy ? null : () => _toggleDj(u, false),
                          )
                        : null,
                  ),
                ),
              if (_canManage) ...[
                const SizedBox(height: 8),
                Text(
                  'Aşağıdan odadaki kullanıcıları DJ olarak ekleyin',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _pickDj,
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF25F4EE)),
                  label: const Text(
                    'Odadan DJ Ekle',
                    style: TextStyle(color: Color(0xFF25F4EE)),
                  ),
                ),
                if (_eligible.isEmpty)
                  Text(
                    'Eklenebilecek kullanıcı yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ownerInRoom
                      ? '👑 Oda sahibi odada — DJ\'ler yalnızca izin verildiğinde çalabilir'
                      : 'Oda sahibi yok — DJ sırası aktif',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF25F4EE),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
