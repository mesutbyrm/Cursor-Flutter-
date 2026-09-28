import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shorts_provider.dart';

class ShortsPage extends ConsumerWidget {
  const ShortsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Kısa Videolar'), elevation: 0), body: shortsAsync.when(data: (shorts) => shorts.isEmpty ? const Center(child: Text('Video bulunamadı')) : ListView.builder(padding: const EdgeInsets.all(8), itemCount: shorts.length, itemBuilder: (c, i) { final s = shorts[i]; return Card(margin: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [if (s.thumbnailUrl != null) Image.network(s.thumbnailUrl!, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[300])) else Container(height: 200, color: Colors.grey[300]), Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(s.username, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Row(children: [const Icon(Icons.favorite_border, size: 16), const SizedBox(width: 4), Text('${s.likes}')]), Row(children: [const Icon(Icons.comment_outlined, size: 16), const SizedBox(width: 4), Text('${s.comments}')]), Row(children: [const Icon(Icons.share, size: 16), const SizedBox(width: 4), Text('${s.shares}')])])]))]), ); }), loading: () => const Center(child: CircularProgressIndicator()), error: (e, st) => Center(child: Text('Hata: $e'))));
  }
}
