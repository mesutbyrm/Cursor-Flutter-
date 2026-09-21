import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/direct_messages_provider.dart';

class DirectMessagesScreen extends ConsumerWidget {
  const DirectMessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doğrudan Mesajlar'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final conversationsAsync = ref.watch(userConversationsProvider(''));

          return conversationsAsync.when(
            data: (conversations) {
              if (conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz sohbet yok',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.cyan[200],
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Sohbet ${index + 1}'),
                    subtitle: const Text('Son mesaj...'),
                    trailing: Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {},
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[400],
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
