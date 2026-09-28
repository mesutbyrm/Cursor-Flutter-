import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/co_broadcast_provider.dart';

class CoBroadcastPage extends ConsumerWidget {
  final String broadcastId;
  const CoBroadcastPage({Key? key, required this.broadcastId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coBroadcastAsync = ref.watch(coBroadcastProvider(broadcastId));
    return Scaffold(appBar: AppBar(title: const Text('Ortak Yayın'), elevation: 0), body: coBroadcastAsync.when(data: (broadcast) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(broadcast.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(broadcast.description, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(children: [Text('${broadcast.viewerCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)), const Text('İzleyici', style: TextStyle(fontSize: 11, color: Colors.grey))]), Column(children: [Text(broadcast.hasGuest ? 'Var' : 'Yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: broadcast.hasGuest ? Colors.green : Colors.red)), const Text('Misafir', style: TextStyle(fontSize: 11, color: Colors.grey))])]), const SizedBox(height: 16), if (broadcast.isLive) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fiber_manual_record, color: Colors.red, size: 8), SizedBox(width: 8), Text('CANLI', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))]))])))])), ]), loading: () => const Center(child: CircularProgressIndicator()), error: (e, st) => Center(child: Text('Hata: $e'))));
  }
}
