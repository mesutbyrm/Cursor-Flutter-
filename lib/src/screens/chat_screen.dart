import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ChatRoom>> rooms = ref.watch(chatRoomsProvider);
    return ResponsiveMaxWidth(
      child: rooms.when(
        data: (List<ChatRoom> items) {
          if (items.isEmpty) {
            return const _EmptyChatRooms();
          }
          final ChatRoom selected = items.firstWhere(
            (ChatRoom room) => room.id == _selectedRoomId,
            orElse: () => items.first,
          );
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth > 760;
              final Widget roomList = _RoomList(
                rooms: items,
                selectedRoomId: selected.id,
                onSelected: (String id) => setState(() => _selectedRoomId = id),
              );
              final Widget conversation = _Conversation(room: selected);

              if (wide) {
                return Row(
                  children: <Widget>[
                    SizedBox(width: 330, child: roomList),
                    Expanded(child: conversation),
                  ],
                );
              }
              return Column(
                children: <Widget>[
                  SizedBox(height: 190, child: roomList),
                  Expanded(child: conversation),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('$error')),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelected,
  });

  final List<ChatRoom> rooms;
  final String selectedRoomId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: rooms.length + 1,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const SectionHeader(
            title: 'Sohbet odaları',
            subtitle: 'Gerçek zamanlı mesaj, grup ve sesli odalar',
          );
        }
        final ChatRoom room = rooms[index - 1];
        return GlassCard(
          padding: const EdgeInsets.all(14),
          onTap: () => onSelected(room.id),
          child: Row(
            children: <Widget>[
              GradientAvatar(
                imageUrl: room.avatarUrl,
                radius: 24,
                isLive: room.isVoice,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      room.topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        StatPill(
                          icon: Icons.circle,
                          label: 'online',
                          value: compactNumber(room.onlineCount),
                        ),
                        if (room.isVoice)
                          const StatPill(
                            icon: Icons.mic,
                            label: 'sesli',
                            value: 'aktif',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (room.unreadCount > 0)
                Badge(label: Text('${room.unreadCount}')),
            ],
          ),
        );
      },
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<ChatMessage>>(
      future: ref
          .read(canlifalRepositoryProvider.future)
          .then(
            (CanlifalRepository repository) => repository.getMessages(room.id),
          ),
      builder: (BuildContext context, AsyncSnapshot<List<ChatMessage>> snapshot) {
        final List<ChatMessage> messages = snapshot.data ?? <ChatMessage>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          child: GlassCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            room.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Moderatörler: ${room.moderators.map((AppUser user) => user.displayName).join(', ')}',
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.block)),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.shield_outlined),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Bu odada henüz mesaj yok veya mesajları görmek için giriş yapmanız gerekiyor.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ChatMessage message = messages[index];
                            final bool mine =
                                message.sender.id ==
                                ref.watch(authControllerProvider).user?.id;
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? const Color(0xFF7C3AED)
                                      : Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      message.sender.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(message.body),
                                    Text(
                                      message.sentAt,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz...',
                    prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyChatRooms extends StatelessWidget {
  const _EmptyChatRooms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Canlifal sohbet odaları şu anda boş veya yüklenemiyor.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
