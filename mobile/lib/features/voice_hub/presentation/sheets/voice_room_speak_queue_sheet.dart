import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';

/// Moderatör — el kaldıran / dinleyici kuyruğu (web: konuşmacı sırası).
void showVoiceSpeakQueueSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
}) {
  if (!perms.canAssignSeats && !perms.isRoomOwner && !perms.isSiteAdmin) {
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _SpeakQueueSheet(
        room: room,
        live: live,
        perms: perms,
      ),
    ),
  );
}

class _SpeakQueueSheet extends ConsumerStatefulWidget {
  const _SpeakQueueSheet({
    required this.room,
    required this.live,
    required this.perms,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;

  @override
  ConsumerState<_SpeakQueueSheet> createState() => _SpeakQueueSheetState();
}

class _SpeakQueueSheetState extends ConsumerState<_SpeakQueueSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<String> _pendingIds = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final ids = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .fetchSpeakRequests();
      if (mounted) setState(() => _pendingIds = ids);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<int> get _occupiedSeats => widget.live.presence
      .map((p) => p.seatIndex)
      .whereType<int>()
      .toSet();

  Set<String> get _onStageIds => widget.live.presence
      .where((p) => p.seatIndex != null && p.seatIndex! >= 0)
      .map((p) => p.id)
      .toSet();

  int? _firstFreeSeat() {
    for (var i = 2; i <= 11; i++) {
      if (!_occupiedSeats.contains(i)) return i;
    }
    return null;
  }

  Future<void> _assign(ChatRoomPresence user) async {
    final seat = _firstFreeSeat();
    if (seat == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Boş koltuk yok')),
        );
      }
      return;
    }
    final ctrl = ref.read(voiceRoomLiveProvider(widget.room.liveKey).notifier);
    final err = await ctrl.assignSeat(seatIndex: seat, userId: user.id);
    if (mounted && err != null) {
      showJetonAwareError(context, err, ref: ref);
    }
  }

  Future<void> _approve(String userId) async {
    final ctrl = ref.read(voiceRoomLiveProvider(widget.room.liveKey).notifier);
    final err = await ctrl.approveSpeakRequest(userId);
    if (mounted) {
      if (err != null) {
        showJetonAwareError(context, err, ref: ref);
      } else {
        setState(() => _pendingIds.remove(userId));
      }
    }
  }

  Future<void> _makeDj(String userId) async {
    final ctrl = ref.read(voiceRoomLiveProvider(widget.room.liveKey).notifier);
    final err = await ctrl.addRoomDj(userId);
    if (mounted && err != null) {
      showJetonAwareError(context, err, ref: ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listeners = widget.live.presence
        .where((p) => !_onStageIds.contains(p.id))
        .toList();

    final pendingUsers = widget.live.presence
        .where((p) => _pendingIds.contains(p.id))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Konuşmacı yönetimi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: 'El kaldıranlar (${pendingUsers.length})'),
                Tab(text: 'Tüm dinleyiciler (${listeners.length})'),
              ],
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // El kaldıranlar
                  _loading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : pendingUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pan_tool_outlined,
                                      size: 36, color: Colors.white38),
                                  const SizedBox(height: 8),
                                  Text(
                                    'El kaldıran yok',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: _loadPending,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Yenile'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scroll,
                              itemCount: pendingUsers.length,
                              itemBuilder: (_, i) {
                                final p = pendingUsers[i];
                                return _ListenerTile(
                                  user: p,
                                  approveLabel: 'Onayla',
                                  onApprove: () => _approve(p.id),
                                  onDj: widget.perms.canManageDj
                                      ? () => _makeDj(p.id)
                                      : null,
                                );
                              },
                            ),

                  // Tüm dinleyiciler
                  listeners.isEmpty
                      ? Center(
                          child: Text(
                            'Bekleyen dinleyici yok',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          itemCount: listeners.length,
                          itemBuilder: (_, i) {
                            final p = listeners[i];
                            return _ListenerTile(
                              user: p,
                              approveLabel: 'Ses ver',
                              onApprove: () => _assign(p),
                              onDj: widget.perms.canManageDj
                                  ? () => _makeDj(p.id)
                                  : null,
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerTile extends StatelessWidget {
  const _ListenerTile({
    required this.user,
    required this.approveLabel,
    required this.onApprove,
    this.onDj,
  });

  final ChatRoomPresence user;
  final String approveLabel;
  final VoidCallback onApprove;
  final VoidCallback? onDj;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: user.image != null && user.image!.isNotEmpty
            ? canlifalImageProvider(user.image!)
            : null,
        child: user.image == null || user.image!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.displayName),
      subtitle: user.chatRole != null
          ? Text(user.chatRole!, style: const TextStyle(fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDj != null)
            IconButton(
              tooltip: 'DJ yap',
              icon: const Icon(Icons.headphones_rounded, size: 20),
              onPressed: onDj,
            ),
          FilledButton.tonal(
            onPressed: onApprove,
            child: Text(approveLabel),
          ),
        ],
      ),
    );
  }
}
