import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../shared/ui.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  ChatRoom? _activeRoom;
  bool _mic = false;

  @override
  Widget build(BuildContext context) {
    if (_activeRoom != null) {
      return _RoomDetail(
        room: _activeRoom!,
        mic: _mic,
        onBack: () => setState(() => _activeRoom = null),
        onMic: _toggleMic,
      );
    }
    final rooms = ref.watch(roomsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        SectionHeader(title: 'Sohbet ve sesli odalar', action: 'Oda aç'),
        GlassCard(
          child: Row(
            children: const <Widget>[
              Icon(Icons.shield_moon),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gerçek zamanlı mesajlaşma, grup odaları, moderasyon ve online kullanıcı listesi.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        rooms.when(
          data: (items) => Column(
            children: items
                .map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      onTap: () => setState(() => _activeRoom = room),
                      child: Row(
                        children: <Widget>[
                          Text(room.icon, style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${room.speakerCount} konuşmacı • ${room.onlineCount} online • ${room.ownerName}',
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          error: (error, _) => ErrorState(message: 'Odalar alınamadı: $error'),
          loading: () => const LoadingState(label: 'Odalar yükleniyor'),
        ),
      ],
    );
  }

  Future<void> _toggleMic(ChatRoom room) async {
    final next = !_mic;
    setState(() => _mic = next);
    await ref.read(apiProvider).roomVoice(room.id, next);
  }
}

class _RoomDetail extends StatelessWidget {
  const _RoomDetail({
    required this.room,
    required this.mic,
    required this.onBack,
    required this.onMic,
  });

  final ChatRoom room;
  final bool mic;
  final VoidCallback onBack;
  final ValueChanged<ChatRoom> onMic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filled(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                room.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: premiumGradient(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(room.icon, style: const TextStyle(fontSize: 42)),
              const SizedBox(height: 14),
              Text(
                '${room.onlineCount} online kullanıcı',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Koltuk sistemi, moderasyon, hediye ve gerçek zamanlı mesajlaşma hazır.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, index) => GlassCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(index == 0 ? Icons.workspace_premium : Icons.event_seat),
                Text(
                  index == 0 ? 'Host' : 'Koltuk ${index + 1}',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onMic(room),
          icon: Icon(mic ? Icons.mic : Icons.mic_off),
          label: Text(mic ? 'Mikrofon açık' : 'Koltuk iste / mikrofona katıl'),
        ),
      ],
    );
  }
}
