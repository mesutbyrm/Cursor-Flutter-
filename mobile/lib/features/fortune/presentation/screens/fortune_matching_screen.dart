import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fortune_matching_provider.dart';

class FortuneMatchingScreen extends ConsumerStatefulWidget {
  const FortuneMatchingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FortuneMatchingScreen> createState() => _FortuneMatchingScreenState();
}

class _FortuneMatchingScreenState extends ConsumerState<FortuneMatchingScreen> {
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fal Eşleştirmesi'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final matchesAsync = ref.watch(
            fortuneMatchesProvider((
              limit: _pageSize,
              offset: _currentPage * _pageSize,
            )),
          );

          return matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.pink[200],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz eşleştirme yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Eşleştirme Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        onPressed: () => _showCreateMatchDialog(context),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return _buildMatchCard(context, ref, match);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Hata: $err'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMatchDialog(context),
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add),
        label: const Text('Eşleştir'),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, WidgetRef ref, FortuneMatch match) {
    final scorePercentage = (match.compatibilityScore * 100).toInt();
    final scoreColor = _getScoreColor(match.compatibilityScore);

    return GestureDetector(
      onTap: () => _showMatchDetail(context, ref, match),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [scoreColor.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uyum Puanı',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$scorePercentage%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scoreColor,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: scoreColor,
                              size: 40,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$scorePercentage%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (match.analysis != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      match.analysis!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                if (match.recommendations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      children: match.recommendations.take(2).map((rec) {
                        return Chip(
                          label: Text(
                            rec,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.pink[50],
                          side: BorderSide(color: Colors.pink[200]!),
                        );
                      }).toList(),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('d MMMM', 'tr_TR').format(match.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (!match.shared)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Paylaş'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[300],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _shareMatch(ref, match.id),
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[400], size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Paylaşıldı',
                            style: TextStyle(fontSize: 11, color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 0.75) {
      return Colors.red[400]!;
    } else if (score > 0.6) {
      return Colors.pink[400]!;
    } else {
      return Colors.orange[400]!;
    }
  }

  void _showMatchDetail(BuildContext context, WidgetRef ref, FortuneMatch match) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final detailAsync = ref.watch(fortuneMatchDetailProvider(match.id));

          return detailAsync.when(
            data: (detail) => Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Eşleştirme Detayları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${(detail.compatibilityScore * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink[400],
                                ),
                              ),
                              const Text('Uyum Puanı'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${detail.recommendations.length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink[400],
                                ),
                              ),
                              const Text('Tavsiye'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (detail.analysis != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analiz',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail.analysis!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    if (detail.recommendations.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Öneriler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...detail.recommendations.map((rec) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.pink[400], size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rec)),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Sonuçları Paylaş'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        onPressed: () {
                          _shareMatch(ref, match.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
          );
        },
      ),
    );
  }

  void _showCreateMatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eşleştirme Başlat'),
        content: const Text('Hangi kullanıcıyla eşleştirme yapmak istiyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eşleştirme özellikleri yakında gelecek')),
              );
            },
            child: const Text('Devam'),
          ),
        ],
      ),
    );
  }

  void _shareMatch(WidgetRef ref, String matchId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eşleştirme paylaşıldı')),
    );
  }
}
