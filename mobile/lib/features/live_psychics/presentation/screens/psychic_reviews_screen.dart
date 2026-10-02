import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/psychic_review_entity.dart';
import '../controllers/psychics_list_controller.dart';
import '../providers/live_psychics_providers.dart';

/// Giriş yapan falcının aldığı değerlendirmeler
/// (`GET /api/fortune-tellers/{id}/reviews`, gerçek veri).
final psychicMyReviewsProvider =
    FutureProvider.autoDispose<List<PsychicReviewEntity>>((ref) async {
  final profile = ref.watch(approvedPsychicProvider).profile;
  if (profile == null || profile.id.isEmpty) return const [];
  return ref.read(livePsychicsRepositoryProvider).fetchReviews(profile.id);
});

class PsychicReviewsScreen extends ConsumerWidget {
  const PsychicReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(psychicMyReviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlar ve puan')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yorumlar yüklenemedi.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(psychicMyReviewsProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(child: Text('Henüz değerlendirme yok.'));
          }
          final avg =
              reviews.fold<int>(0, (a, r) => a + r.rating) / reviews.length;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(psychicMyReviewsProvider);
              await ref.read(psychicMyReviewsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Text(
                    '${avg.toStringAsFixed(1)} ★  ·  ${reviews.length} değerlendirme',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  );
                }
                return _ReviewTile(review: reviews[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final PsychicReviewEntity review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt == null
        ? null
        : DateFormat('d MMM y', 'tr').format(review.createdAt!.toLocal());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('★' * review.rating.clamp(0, 5),
                  style: const TextStyle(color: Color(0xFFFFC107))),
              const Spacer(),
              if (date != null)
                Text(date, style: const TextStyle(fontSize: 12)),
            ],
          ),
          if ((review.clientName ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.clientName!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!),
          ],
        ],
      ),
    );
  }
}
