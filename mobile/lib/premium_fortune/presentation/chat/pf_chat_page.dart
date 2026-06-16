import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_chat.dart';
import '../widgets/pf_glass_card.dart';

final pfConversationsProvider =
    FutureProvider<List<PfConversation>>((ref) async {
  final user = ref.watch(pfEffectiveUserProvider);
  if (user == null) return [];
  final result = await ref.read(pfChatRepositoryProvider).getConversations(user.id);
  return result.valueOrNull ?? [];
});

class PfChatListPage extends ConsumerWidget {
  const PfChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convs = ref.watch(pfConversationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Mesajlar')),
      body: convs.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: PfGlassCard(
                onTap: () => context.push('/premium/chat/${c.id}'),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: PfTheme.purple,
                      child: Text((c.tellerName ?? '?')[0]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.tellerName ?? 'Sohbet',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: PfTheme.pink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${c.unreadCount}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class PfChatRoomPage extends ConsumerStatefulWidget {
  const PfChatRoomPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<PfChatRoomPage> createState() => _PfChatRoomPageState();
}

class _PfChatRoomPageState extends ConsumerState<PfChatRoomPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;

    await ref.read(pfChatRepositoryProvider).sendText(
          conversationId: widget.conversationId,
          senderId: user.id,
          text: text,
        );
    _textCtrl.clear();
    setState(() {});
  }

  Future<void> _sendImage() async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await ref.read(pfChatRepositoryProvider).sendImage(
          conversationId: widget.conversationId,
          senderId: user.id,
          localImagePath: file.path,
        );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(pfEffectiveUserProvider);
    final messagesStream =
        ref.read(pfChatRepositoryProvider).watchMessages(widget.conversationId);

    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Sohbet')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PfChatMessage>>(
              stream: messagesStream,
              builder: (context, snap) {
                final messages = snap.data ?? [];
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderId == user?.id;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? PfTheme.purple.withValues(alpha: 0.6)
                              : PfTheme.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.type == PfMessageType.image)
                              const Icon(Icons.image_rounded, size: 40)
                            else if (m.type == PfMessageType.audio)
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_rounded, size: 20),
                                  SizedBox(width: 4),
                                  Text('Ses kaydı'),
                                ],
                              )
                            else
                              Text(m.content),
                            if (m.isRead && isMe)
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(Icons.done_all, size: 14,
                                    color: Colors.white38),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sendImage,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ses kaydı — production\'da record paketi ile'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yazın...',
                        filled: true,
                        fillColor: PfTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, color: PfTheme.purple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
