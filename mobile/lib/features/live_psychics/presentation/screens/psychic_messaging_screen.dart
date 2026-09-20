import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Mesajlaşma/Chat — Falcıya özel mesajlaşma, seans öncesi/sonrası haber
class PsychicMessagingScreen extends ConsumerStatefulWidget {
  const PsychicMessagingScreen({super.key});

  @override
  ConsumerState<PsychicMessagingScreen> createState() =>
      _PsychicMessagingScreenState();
}

class _PsychicMessagingScreenState extends ConsumerState<PsychicMessagingScreen> {
  final messageController = TextEditingController();

  final messages = [
    {
      'id': 'msg_001',
      'senderName': 'Aylin Şahin',
      'senderAvatar': '👩',
      'content': 'Merhaba! Seans öncesi merak ettiğim sorular var.',
      'timestamp': '10:30',
      'isFromTeller': false,
      'isRead': true,
      'type': 'text',
    },
    {
      'id': 'msg_002',
      'senderName': 'Siz',
      'senderAvatar': '👳',
      'content': 'Merhaba! Tabii ki, ne soracağını söyle.',
      'timestamp': '10:32',
      'isFromTeller': true,
      'isRead': true,
      'type': 'text',
    },
    {
      'id': 'msg_003',
      'senderName': 'Aylin Şahin',
      'senderAvatar': '👩',
      'content': 'Seans ne kadar sürecek? İyim mi yoksa kötü haberler mi?',
      'timestamp': '10:33',
      'isFromTeller': false,
      'isRead': true,
      'type': 'text',
    },
    {
      'id': 'msg_004',
      'senderName': 'Siz',
      'senderAvatar': '👳',
      'content': 'Seans 30 dk. Pozitif haberler var, seans sırasında detaylı anlatacağım.',
      'timestamp': '10:35',
      'isFromTeller': true,
      'isRead': true,
      'type': 'text',
    },
    {
      'id': 'msg_005',
      'senderName': 'Aylin Şahin',
      'senderAvatar': '👩',
      'content': 'Sevinç! 15:00\'de seansı başlatalım mı?',
      'timestamp': '11:45',
      'isFromTeller': false,
      'isRead': false,
      'type': 'text',
    },
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String content) {
    if (content.isEmpty) return;
    messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mesaj gönderildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylin Şahin',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              'Son mesaj: 11:45',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesli arama başlatılıyor')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context.pop(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: DiscoverBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  final isFromTeller = msg['isFromTeller'] as bool;

                  return Column(
                    crossAxisAlignment: isFromTeller
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (index > 0 && messages.length - 1 - index < messages.length)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MessageBubble(
                            message: msg,
                            isFromTeller: isFromTeller,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MessageBubble(
                            message: msg,
                            isFromTeller: isFromTeller,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resim ekleme')),
                    ),
                    icon: const Icon(Icons.image_outlined),
                    iconSize: 20,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () =>
                        _sendMessage(messageController.text),
                    icon: const Icon(Icons.send_rounded),
                    iconSize: 20,
                    color: AppThemeColors.accentCyan,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFromTeller,
  });

  final Map<String, dynamic> message;
  final bool isFromTeller;

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String;
    final timestamp = message['timestamp'] as String;

    return Row(
      mainAxisAlignment:
          isFromTeller ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isFromTeller) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                message['senderAvatar'] as String,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isFromTeller
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isFromTeller
                      ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        if (isFromTeller) ...[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                message['senderAvatar'] as String,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
