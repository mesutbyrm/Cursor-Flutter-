import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Seans geçmişi — Müşteri seansları, notlar, takip önerileri
class PsychicSessionsScreen extends ConsumerStatefulWidget {
  const PsychicSessionsScreen({super.key});

  @override
  ConsumerState<PsychicSessionsScreen> createState() =>
      _PsychicSessionsScreenState();
}

class _PsychicSessionsScreenState extends ConsumerState<PsychicSessionsScreen> {
  String selectedSort = 'recent';

  final List<Map<String, dynamic>> sessions = [
    {
      'id': 'sess_001',
      'customerName': 'Aylin Şahin',
      'customerAvatar': '👩',
      'date': '2025-02-15 14:30',
      'duration': 45,
      'status': 'completed',
      'rating': 5,
      'earnings': 225,
      'notes':
          'Aşk hayatında yeni bir başlangıç hissediyor. Ağustos ayında önemli bir fırsat görmüş. Takip seans önerildi.',
      'followUpDate': '2025-03-15',
      'recommendations': ['Haftalık takip seans', 'Çift ilişkilerine odaklan'],
    },
    {
      'id': 'sess_002',
      'customerName': 'Elif Kara',
      'customerAvatar': '👩',
      'date': '2025-02-12 09:00',
      'duration': 60,
      'status': 'completed',
      'rating': 5,
      'earnings': 300,
      'notes':
          'Kariyer değişikliğini düşünüyor. Şu an işini bırakmaya hazırlanıyor. Yeni proje önerisi görmüş.',
      'followUpDate': '2025-02-26',
      'recommendations': ['Kariyer danışmanlığı', '2 hafta sonra tekrar'],
    },
    {
      'id': 'sess_003',
      'customerName': 'Mehmet Yılmaz',
      'customerAvatar': '👨',
      'date': '2025-02-10 10:15',
      'duration': 30,
      'status': 'completed',
      'rating': 4,
      'earnings': 100,
      'notes':
          'Ailesi ile sorunları var. Annesi ile görüşme gerekli. Sabırlı ve yapıcı yaklaşım önerildi.',
      'followUpDate': '2025-02-24',
      'recommendations': ['Aile danışmanlığı', 'Iletişim becerisi'],
    },
    {
      'id': 'sess_004',
      'customerName': 'Zara Hasan',
      'customerAvatar': '👩',
      'date': '2025-02-05 18:45',
      'duration': 30,
      'status': 'completed',
      'rating': 5,
      'earnings': 100,
      'notes':
          'Yeni müşteri. Özgüven sorunu var. Gelecek hakkında pozitif mesajlar aldı. Mutlu göründü.',
      'followUpDate': '2025-02-19',
      'recommendations': ['Özgüven geliştirme', 'Haftalık takip'],
    },
    {
      'id': 'sess_005',
      'customerName': 'Can Demir',
      'customerAvatar': '👨',
      'date': '2025-01-28 16:20',
      'duration': 45,
      'status': 'completed',
      'rating': 4,
      'earnings': 180,
      'notes':
          'İş hayatında hızlı ilerleme görecek. Ağustos ve eylül aylarında kritik kararlar alacak.',
      'followUpDate': '2025-03-28',
      'recommendations': ['Aylık takip', 'Karar verme desteği'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    var sortedSessions = [...sessions];

    if (selectedSort == 'recent') {
      sortedSessions.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    } else if (selectedSort == 'oldest') {
      sortedSessions.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    } else if (selectedSort == 'duration') {
      sortedSessions.sort((a, b) => (b['duration'] as int).compareTo(a['duration']));
    } else if (selectedSort == 'earnings') {
      sortedSessions.sort((a, b) => (b['earnings'] as int).compareTo(a['earnings']));
    }

    final totalSessions = sessions.length;
    final totalEarnings = sessions.fold<int>(0, (sum, s) => sum + (s['earnings'] as int));
    final totalDuration = sessions.fold<int>(0, (sum, s) => sum + (s['duration'] as int));
    final avgRating = sessions.isEmpty
        ? 0.0
        : sessions.fold<int>(0, (sum, s) => sum + (s['rating'] as int)) /
            sessions.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Seans Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CSV dışa aktarılıyor...'),
                duration: Duration(seconds: 2),
              ),
            ),
          ),
        ],
      ),
      body: DiscoverBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryBox(
                      icon: Icons.video_call_outlined,
                      label: 'Toplam',
                      value: '$totalSessions',
                      color: AppThemeColors.accentCyan,
                    ),
                    _SummaryBox(
                      icon: Icons.schedule_outlined,
                      label: 'Süre',
                      value: '${totalDuration}s',
                      color: Colors.orange,
                    ),
                    _SummaryBox(
                      icon: Icons.payments_outlined,
                      label: 'Kazanç',
                      value: '$totalEarnings',
                      color: Colors.green,
                    ),
                    _SummaryBox(
                      icon: Icons.star_outlined,
                      label: 'Ort. Puan',
                      value: avgRating.toStringAsFixed(1),
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sort Options
              const Text(
                'Sıralama',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SortButton(
                      label: 'En Yeni',
                      value: 'recent',
                      selected: selectedSort == 'recent',
                      onTap: () => setState(() => selectedSort = 'recent'),
                    ),
                    const SizedBox(width: 8),
                    _SortButton(
                      label: 'En Eski',
                      value: 'oldest',
                      selected: selectedSort == 'oldest',
                      onTap: () => setState(() => selectedSort = 'oldest'),
                    ),
                    const SizedBox(width: 8),
                    _SortButton(
                      label: 'Süreye Göre',
                      value: 'duration',
                      selected: selectedSort == 'duration',
                      onTap: () => setState(() => selectedSort = 'duration'),
                    ),
                    const SizedBox(width: 8),
                    _SortButton(
                      label: 'Kazanca Göre',
                      value: 'earnings',
                      selected: selectedSort == 'earnings',
                      onTap: () => setState(() => selectedSort = 'earnings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sessions List
              const Text(
                'Seans Listesi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...sortedSessions.map((session) {
                return _SessionCard(
                  session: session,
                  onViewDetails: () => _showSessionDetails(session),
                  onEditNotes: () => _showEditNotesDialog(session),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${session['customerName']} - Seans Detayları'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Tarih', session['date']),
              _DetailRow('Süre', '${session['duration']} dakika'),
              _DetailRow('Kazanç', '${session['earnings']} jeton'),
              _DetailRow('Puan', '⭐ ${session['rating']}/5'),
              const SizedBox(height: 16),
              const Text(
                'Notlar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session['notes'],
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Takip Tarihi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session['followUpDate'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemeColors.accentCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Öneriler',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...((session['recommendations'] as List).cast<String>()).map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(Map<String, dynamic> session) {
    final notesController = TextEditingController(text: session['notes']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${session['customerName']} - Notları Düzenle'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Seans notları...',
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = sessions.indexWhere((s) => s['id'] == session['id']);
                if (idx >= 0) {
                  sessions[idx]['notes'] = notesController.text;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notlar kaydedildi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? AppThemeColors.accentCyan
            : Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onViewDetails,
    required this.onEditNotes,
  });

  final Map<String, dynamic> session;
  final VoidCallback onViewDetails;
  final VoidCallback onEditNotes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.15),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      session['customerAvatar'],
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['customerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session['date'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session['earnings']} jeton',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '⭐ ${session['rating']}/5',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${session['duration']} dakika seans',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'Takip: ${session['followUpDate']}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                session['notes'],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.expand_outlined, size: 14),
                    label: const Text('Detaylar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditNotes,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Notlar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
