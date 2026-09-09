import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/domain/entities/chat_room_presence.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';

/// Admin — sesli oda mini yönetim (katılımcı listesi + kick).
Future<void> showAdminVoiceRoomMiniPanel({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A0F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _Panel(room: room),
  );
}

class _Panel extends ConsumerStatefulWidget {
  const _Panel({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel> {
  final _userIdCtrl = TextEditingController();
  var _busy = false;
  var _loadingParticipants = true;
  List<ChatRoomPresence> _participants = const [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  String get _roomKey =>
      widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;

  Future<void> _loadParticipants() async {
    setState(() {
      _loadingParticipants = true;
      _loadError = null;
    });
    try {
      final page = await ref.read(chatRoomRemoteProvider).fetchPresencePage(
            _roomKey,
            alternateKey: widget.room.id,
          );
      if (mounted) {
        setState(() {
          _participants = page.users;
          _loadingParticipants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = ApiException.userMessage(e);
          _loadingParticipants = false;
        });
      }
    }
  }

  Future<void> _kick(String userId) async {
    if (userId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(chatRoomRemoteProvider).kickUser(
            roomKey: _roomKey,
            userId: userId,
            reason: 'admin',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı odadan atıldı')),
        );
        await _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              room.nameTr.isNotEmpty ? room.nameTr : 'Sesli Oda',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Oda: ${room.id} · ${_participants.length} katılımcı',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/voice-room/${room.id}', extra: room);
                    },
                    icon: const Icon(Icons.meeting_room_outlined, size: 18),
                    label: const Text('Odaya gir'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadParticipants,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Katılımcılar',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loadingParticipants
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(child: Text(_loadError!))
                      : _participants.isEmpty
                          ? const Center(
                              child: Text(
                                'Katılımcı bulunamadı — presence API boş.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: _participants.length,
                              itemBuilder: (_, i) {
                                final p = _participants[i];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    child: Text(
                                      p.name.isNotEmpty
                                          ? p.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    p.id,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.person_remove_outlined,
                                      color: AppThemeColors.liveRed,
                                      size: 20,
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => _kick(p.id),
                                  ),
                                );
                              },
                            ),
            ),
            const Divider(height: 20),
            const Text(
              'Manuel kullanıcı ID ile at',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı ID',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _kick(_userIdCtrl.text.trim()),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('At'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
