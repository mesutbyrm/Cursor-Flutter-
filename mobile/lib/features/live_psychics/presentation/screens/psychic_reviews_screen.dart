import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Yorum Yönetimi — Müşteri yorumları, yanıt, göm, düzen.
class PsychicReviewsScreen extends ConsumerStatefulWidget {
  const PsychicReviewsScreen({super.key});

  @override
  ConsumerState<PsychicReviewsScreen> createState() =>
      _PsychicReviewsScreenState();
}

class _PsychicReviewsScreenState extends ConsumerState<PsychicReviewsScreen> {
  String filterStatus = 'all'; // all, pending, hidden, reported

  final reviews = [
    {
      'id': 'rev_001',
      'userName': 'Mehmet K.',
      'rating': 5,
      'text': 'Harika bir seans oldu, çok doğru bilgiler verdin. Tekrar gelirim.',
      'date': '2 gün önce',
      'status': 'visible', // visible, pending, hidden, reported
      'hasReply': false,
      'isVerified': true,
    },
    {
      'id': 'rev_002',
      'userName': 'Fatma D.',
      'rating': 4,
      'text': 'İyi seans ama biraz daha detaylı olabilirdi.',
      'date': '1 hafta önce',
      'status': 'visible',
      'hasReply': true,
      'reply': 'Teşekkürler! Bir sonraki seansınızda daha detaylı bakarim.',
      'isVerified': true,
    },
    {
      'id': 'rev_003',
      'userName': 'Ali T.',
      'rating': 3,
      'text': 'Ortalama bir deneyim oldu.',
      'date': '2 hafta önce',
      'status': 'visible',
      'hasReply': false,
      'isVerified': false,
    },
    {
      'id': 'rev_004',
      'userName': 'Emre Y.',
      'rating': 2,
      'text': 'Beklendiği kadar iyi değildi. Hayal kırıklığına uğradım.',
      'date': '1 ay önce',
      'status': 'pending', // Bekleme (yanıt bekleniyor)
      'hasReply': false,
      'isVerified': true,
    },
    {
      'id': 'rev_005',
      'userName': 'Aylin S.',
      'rating': 1,
      'text': 'Hiç fayda sağlamadı. Pişmanım.',
      'date': '1 ay önce',
      'status': 'reported', // Şikayetçi
      'hasReply': false,
      'isVerified': true,
    },
  ];

  List<Map<String, dynamic>> _filterReviews() {
    if (filterStatus == 'all') return reviews;
    return reviews.where((r) => r['status'] == filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterReviews();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Yorum Yönetimi',
                      subtitle: 'Müşteri yorumlarını yönet',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Filter tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tümü (${reviews.length})',
                          isActive: filterStatus == 'all',
                          onTap: () =>
                              setState(() => filterStatus = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Cevap Bekleyen (${reviews.where((r) => r['status'] == 'pending').length})',
                          isActive: filterStatus == 'pending',
                          onTap: () =>
                              setState(() => filterStatus = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Gizli (${reviews.where((r) => r['status'] == 'hidden').length})',
                          isActive: filterStatus == 'hidden',
                          onTap: () =>
                              setState(() => filterStatus = 'hidden'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Şikayetçi (${reviews.where((r) => r['status'] == 'reported').length})',
                          isActive: filterStatus == 'reported',
                          onTap: () =>
                              setState(() => filterStatus = 'reported'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Bu filtrede yorum yok',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filtered.length, (i) {
                      final review = filtered[i];
                      return Column(
                        children: [
                          _ReviewCard(
                            review: review,
                            onReply: () => _showReplyDialog(context, review),
                            onHide: () => _showHideConfirm(context, review),
                            onDelete: () =>
                                _showDeleteConfirm(context, review),
                          ),
                          if (i < filtered.length - 1)
                            const SizedBox(height: 12),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, Map<String, dynamic> review) {
    final replyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yanıt Yaz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${review['userName']} — ${review['rating']} yıldız',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              review['text'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Yanıtınızı yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yanıt gönderildi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showHideConfirm(BuildContext context, Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Gizle'),
        content: const Text(
          'Bu yorum profilinde görünmez olacak. Siz ve yorum yazan kişi görebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yorum gizlendi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Gizle'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorum kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yorum silindi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppThemeColors.accentCyan
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? AppThemeColors.accentCyan : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onReply,
    required this.onHide,
    required this.onDelete,
  });

  final Map<String, dynamic> review;
  final VoidCallback onReply;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  Color _getRatingColor() {
    final rating = review['rating'] as int;
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.amber;
    return Colors.red;
  }

  String _getStatusLabel() {
    switch (review['status']) {
      case 'pending':
        return 'Cevap Bekleniyor';
      case 'hidden':
        return 'Gizli';
      case 'reported':
        return 'Şikayetçi';
      default:
        return 'Görünür';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review['userName'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (review['isVerified'] as bool)
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppThemeColors.accentCyan,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (review['rating'] as int)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: _getRatingColor(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review['date'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review['text'] as String,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (review['hasReply'] as bool) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sizin yanıtınız:',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['reply'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!(review['hasReply'] as bool))
                  TextButton.icon(
                    icon: const Icon(Icons.reply_rounded, size: 14),
                    label: const Text('Yanıt'),
                    onPressed: onReply,
                  ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.visibility_off_rounded, size: 14),
                  label: const Text('Gizle'),
                  onPressed: onHide,
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.delete_rounded, size: 14),
                  label: const Text('Sil'),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (review['status']) {
      case 'pending':
        return Colors.amber;
      case 'hidden':
        return Colors.grey;
      case 'reported':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
}
