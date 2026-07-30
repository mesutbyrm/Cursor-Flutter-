import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/short_video_liker.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_count_format.dart';
import '../../../../core/widgets/user_avatar.dart';

Future<void> showShortVideoAnalyticsSheet(
  BuildContext context,
  WidgetRef ref,
  ShortVideoEntity video,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _ShortVideoAnalyticsSheet(video: video),
  );
}

class _ShortVideoAnalyticsSheet extends ConsumerWidget {
  const _ShortVideoAnalyticsSheet({required this.video});

  final ShortVideoEntity video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(shortVideoAnalyticsProvider(video));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: analytics.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _AnalyticsBody(
            title: 'Video analitikleri',
            rows: _rowsFromVideo(video),
          ),
          data: (a) => _AnalyticsBody(
            title: 'Video analitikleri',
            rows: [
              _StatRow('İzlenme', formatShortCount(a.viewsCount)),
              _StatRow('Beğeni', formatShortCount(a.likesCount)),
              _StatRow('Yorum', formatShortCount(a.commentsCount)),
              _StatRow('Paylaşım', formatShortCount(a.sharesCount)),
              _StatRow('Kaydetme', formatShortCount(a.savesCount)),
              if (a.avgWatchSec > 0)
                _StatRow('Ort. izleme', '${a.avgWatchSec.toStringAsFixed(1)} sn'),
              if (a.completionRate > 0)
                _StatRow(
                  'Tamamlama',
                  '${(a.completionRate * 100).clamp(0, 100).toStringAsFixed(0)}%',
                ),
              if (a.duetsCount > 0)
                _StatRow('Düet', formatShortCount(a.duetsCount)),
              if (a.profileVisits > 0)
                _StatRow('Profil tıklama', formatShortCount(a.profileVisits)),
            ],
            likers: a.recentLikers,
          ),
        ),
      ),
    );
  }

  List<_StatRow> _rowsFromVideo(ShortVideoEntity v) => [
        _StatRow('İzlenme', formatShortCount(v.viewsCount)),
        _StatRow('Beğeni', formatShortCount(v.likesCount)),
        _StatRow('Yorum', formatShortCount(v.commentsCount)),
        _StatRow('Paylaşım', formatShortCount(v.sharesCount)),
        _StatRow('Kaydetme', formatShortCount(v.savesCount)),
      ];
}

class _StatRow {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({
    required this.title,
    required this.rows,
    this.likers = const [],
  });

  final String title;
  final List<_StatRow> rows;
  final List<ShortVideoLiker> likers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  row.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        if (likers.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Beğenenler',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: likers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final l = likers[i];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(
                      imageUrl: l.avatarUrl,
                      name: l.label,
                      radius: 22,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        l.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
