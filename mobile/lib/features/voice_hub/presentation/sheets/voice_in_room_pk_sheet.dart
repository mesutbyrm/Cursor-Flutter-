import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/presence_canonical.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../../domain/pk/pk_duration_options.dart';
import '../widgets/premium_2026/pk/pk_duration_picker.dart';

const _maxPerSide = 4;

/// Oda içi kullanıcı PK — `create_user` (takım 1 / takım 2, en fazla 4+4).
Future<void> showVoiceInRoomPkSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
}) async {
  final self = ref.read(authControllerProvider).valueOrNull;
  if (self == null) return;
  final users = presence
      .map(
        (p) => ChatRoomPresence(
          id: canonicalPresenceId(p),
          name: p.name,
          nickname: p.nickname,
          image: p.image,
          chatRole: p.chatRole,
          roleSymbol: p.roleSymbol,
          membership: p.membership,
          seatIndex: p.seatIndex,
          isSpeaking: p.isSpeaking,
          isMuted: p.isMuted,
          micOn: p.micOn,
        ),
      )
      .where((p) => p.id.trim().isNotEmpty)
      .toList(growable: false);
  if (users.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oda içi PK için odada en az iki kullanıcı gerekli'),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _VoiceInRoomPkSheet(
      room: room,
      users: users,
      ownerId: self.id,
    ),
  );
}

class _VoiceInRoomPkSheet extends ConsumerStatefulWidget {
  const _VoiceInRoomPkSheet({
    required this.room,
    required this.users,
    required this.ownerId,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> users;
  final String ownerId;

  @override
  ConsumerState<_VoiceInRoomPkSheet> createState() =>
      _VoiceInRoomPkSheetState();
}

class _VoiceInRoomPkSheetState extends ConsumerState<_VoiceInRoomPkSheet> {
  final _side1 = <String>{};
  final _side2 = <String>{};
  var _duration = pkDefaultDurationSeconds;
  var _busy = false;
  var _activeSide = 0;

  String get _roomKey =>
      widget.room.apiRoomKey.isNotEmpty ? widget.room.apiRoomKey : widget.room.id;

  void _toggleUser(ChatRoomPresence p) {
    final id = p.id;
    setState(() {
      if (_side1.contains(id)) {
        _side1.remove(id);
        return;
      }
      if (_side2.contains(id)) {
        _side2.remove(id);
        return;
      }
      if (_activeSide == 0) {
        if (_side1.length >= _maxPerSide) return;
        _side1.add(id);
      } else {
        if (_side2.length >= _maxPerSide) return;
        _side2.add(id);
      }
    });
  }

  Future<void> _start() async {
    if (_busy) return;
    if (_side1.isEmpty || _side2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Her takımda en az bir kişi seçin')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final remote = await ref
          .read(pkBattleRemoteDataSourceProvider)
          .createUserInRoomPk(
            roomId: _roomKey,
            alternateRoomId: widget.room.slug,
            side1UserIds: _side1.toList(),
            side2UserIds: _side2.toList(),
            durationSeconds: _duration,
          );
      if (remote == null || remote.effectiveId.isEmpty) {
        throw const ApiException('Oda içi PK başlatılamadı');
      }
      ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(remote);
      await ref
          .read(pkSessionProvider(
            PkSessionArgs(contextId: _roomKey, kind: PkContextKind.voice),
          ).notifier)
          .loadState(showLoading: false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Oda içi PK başladı — takımlar geri sayım sonrası aktif olur',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Oda içi PK — takım seç',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Takım 1 ve 2’ye en fazla $_maxPerSide kişi (odadaki kullanıcılar)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            PkDurationPicker(
              selectedSeconds: _duration,
              onChanged: _busy ? (_) {} : (v) => setState(() => _duration = v),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Takım 1')),
                ButtonSegment(value: 1, label: Text('Takım 2')),
              ],
              selected: {_activeSide},
              onSelectionChanged: _busy
                  ? null
                  : (s) => setState(() => _activeSide = s.first),
            ),
            const SizedBox(height: 8),
            _TeamSummary(title: 'Takım 1', ids: _side1, users: widget.users),
            const SizedBox(height: 4),
            _TeamSummary(title: 'Takım 2', ids: _side2, users: widget.users),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.users.length,
                itemBuilder: (context, i) {
                  final p = widget.users[i];
                  final in1 = _side1.contains(p.id);
                  final in2 = _side2.contains(p.id);
                  final selected = in1 || in2;
                  return ListTile(
                    dense: true,
                    enabled: !_busy,
                    leading: CircleAvatar(
                      child: Text(
                        p.displayName.isNotEmpty
                            ? p.displayName.characters.first
                            : '?',
                      ),
                    ),
                    title: Text(
                      p.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: selected
                        ? Text(
                            in1 ? 'Takım 1' : 'Takım 2',
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    trailing: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected
                          ? const Color(0xFF9B4DFF)
                          : Colors.white38,
                    ),
                    onTap: () => setState(() => _toggleUser(p)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _start,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9B4DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'PK Başlat',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSummary extends StatelessWidget {
  const _TeamSummary({
    required this.title,
    required this.ids,
    required this.users,
  });

  final String title;
  final Set<String> ids;
  final List<ChatRoomPresence> users;

  @override
  Widget build(BuildContext context) {
    final names = users
        .where((u) => ids.contains(u.id))
        .map((u) => u.displayName)
        .take(4)
        .join(', ');
    return Text(
      '$title (${ids.length}/$_maxPerSide): ${names.isEmpty ? '—' : names}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 11,
      ),
    );
  }
}
