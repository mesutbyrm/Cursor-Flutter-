import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/shorts_providers.dart';

class ShortHashtagPage extends ConsumerWidget {
  const ShortHashtagPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(shortHashtagVideosProvider(name));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text('#${name.replaceAll('#', '')}'),
      ),
      body: videos.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accentPurple),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Bu hashtag ile video yok'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 9 / 14,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final v = list[i];
              return GestureDetector(
                onTap: () => context.push('/shorts?videoId=${v.id}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: v.thumbnailUrl != null
                      ? CanlifalNetworkImage(url: v.thumbnailUrl!, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: Color(0xFF1A0F3D),
                          child: Icon(Icons.play_circle_outline),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
