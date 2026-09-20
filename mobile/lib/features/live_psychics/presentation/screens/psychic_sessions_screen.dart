import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Oturum Geçmişi — Detaylı seans kayıtları, filtreleme, dışa aktarma.
class PsychicSessionsScreen extends ConsumerStatefulWidget {
  const PsychicSessionsScreen({super.key});

  @override
  ConsumerState<PsychicSessionsScreen> createState() =>
      _PsychicSessionsScreenState();
}

class _PsychicSessionsScreenState extends ConsumerState<PsychicSessionsScreen> {
  String filterStatus = 'all'; // all, completed, cancelled, extended
  String sortBy = 'recent'; // recent, oldest, duration, earnings

  final sessions = [
    {
      'id': 'ses_001',
      'customerName': 'Aylin Şahin',
      'date': '2026-09-18',
      'time': '14:30',
      'duration': 45,
      'earnings': 39.99,
      'rating': 5,
      'status': 'completed',
      'sessionType': 'Tarot',
    },
    {
      'id': 'ses_002',
      'customerName': 'Mehmet Kaya',
      'date': '2026-09-17',
      'time': '20:00',
      'duration': 60,
      'earnings': 49.99,
      'rating': 4,
      'status': 'completed',
      'sessionType': 'Numeroloji',
    },
    {
      'id': 'ses_003',
      'customerName': 'Fatma Yüksek',
      'date': '2026-09-16',
      'time': '15:00',
      'duration': 30,
      'earnings': 24.99,
      'rating': 5,
      'status': 'completed',
      'sessionType': 'El Falı',
    },
    {
      'id': 'ses_004',
      'customerName': 'Zeynep Arslan',
      'date': '2026-09-15',
      'time': '19:30',
      'duration': 75,
      'earnings': 59.99,
      'rating': 4,
      'status': 'extended',
      'sessionType': 'Tarot',
      'extensionCount': 1,
    },
    {
      'id': 'ses_005',
      'customerName': 'Ali Demir',
      'date': '2026-09-14',
      'time': '10:00',
      'duration': 0,
      'earnings': 0,
      'rating': null,
      'status': 'cancelled',
      'sessionType': 'Astroloji',
      'cancelledBy': 'customer',
    },
  ];

  List<Map<String, dynamic>> _filterSessions() {
    List<Map<String, dynamic>> filtered = sessions;

    if (filterStatus != 'all') {
      filtered = filtered.where((s) => s['status'] == filterStatus).toList();
    }

    if (sortBy == 'recent') {
      filtered.sort((a, b) => b['date'].compareTo(a['date']));
    } else if (sortBy == 'oldest') {
      filtered.sort((a, b) => a['date'].compareTo(b['date']));
    } else if (sortBy == 'duration') {
      filtered.sort((a, b) => (b['duration'] as int).compareTo(a['duration']));
    } else if (sortBy == 'earnings') {
      filtered.sort((a, b) => (b['earnings'] as double).compareTo(a['earnings']));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterSessions();
    final totalEarnings = filtered
        .fold<double>(0, (sum, s) => sum + (s['earnings'] as double));
    final totalDuration =
        filtered.fold<int>(0, (sum, s) => sum + (s['duration'] as int));

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
                      title: 'Oturum Geçmişi',
                      subtitle: 'Detaylı seans kayıtları',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.download_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV indirildi')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₺${totalEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Kazanç',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: AppThemeColors.accentCyan.withValues(
                            alpha: 0.1,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${totalDuration ~/ 60}sa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppThemeColors.accentCyan,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Toplam Süre',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tümü',
                          isActive: filterStatus == 'all',
                          onTap: () =>
                              setState(() => filterStatus = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Tamamlandı',
                          isActive: filterStatus == 'completed',
                          onTap: () =>
                              setState(() => filterStatus = 'completed'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Uzatıldı',
                          isActive: filterStatus == 'extended',
                          onTap: () =>
                              setState(() => filterStatus = 'extended'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'İptal',
                          isActive: filterStatus == 'cancelled',
                          onTap: () =>
                              setState(() => filterStatus = 'cancelled'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sort
                  Row(
                    children: [
                      const Text(
                        'Sırala:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _SortChip(
                                label: 'Son',
                                isActive: sortBy == 'recent',
                                onTap: () =>
                                    setState(() => sortBy = 'recent'),
                              ),
                              const SizedBox(width: 6),
                              _SortChip(
                                label: 'Eski',
                                isActive: sortBy == 'oldest',
                                onTap: () =>
                                    setState(() => sortBy = 'oldest'),
                              ),
                              const SizedBox(width: 6),
                              _SortChip(
                                label: 'Süre',
                                isActive: sortBy == 'duration',
                                onTap: () =>
                                    setState(() => sortBy = 'duration'),
                              ),
                              const SizedBox(width: 6),
                              _SortChip(
                                label: 'Kazanç',
                                isActive: sortBy == 'earnings',
                                onTap: () =>
                                    setState(() => sortBy = 'earnings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sessions list
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Oturum kaydı yok',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filtered.length, (i) {
                      final session = filtered[i];
                      return Column(
                        children: [
                          _SessionCard(
                            session: session,
                            onViewDetails: () =>
                                _showSessionDetails(context, session),
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

  void _showSessionDetails(
      BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        color: const Color(0xFF0D0618),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oturum Detayları',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Müşteri',
                value: session['customerName'] as String,
              ),
              _DetailRow(
                label: 'Tarih & Saat',
                value: '${session['date']} ${session['time']}',
              ),
              _DetailRow(
                label: 'Türü',
                value: session['sessionType'] as String,
              ),
              _DetailRow(
                label: 'Süre',
                value: '${session['duration']} dakika',
              ),
              _DetailRow(
                label: 'Kazanç',
                value: '₺${(session['earnings'] as double).toStringAsFixed(2)}',
              ),
              if (session['rating'] != null)
                _DetailRow(
                  label: 'Puan',
                  value: '${session['rating']} ⭐',
                ),
              _DetailRow(
                label: 'Durum',
                value: _getStatusLabel(session['status'] as String),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'extended':
        return 'Uzatıldı';
      case 'cancelled':
        return 'İptal edildi';
      default:
        return status;
    }
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

class _SortChip extends StatelessWidget {
  const _SortChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppThemeColors.accentCyan
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? AppThemeColors.accentCyan : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onViewDetails,
  });

  final Map<String, dynamic> session;
  final VoidCallback onViewDetails;

  Color _getStatusColor() {
    switch (session['status']) {
      case 'completed':
        return Colors.green;
      case 'extended':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (session['status']) {
      case 'completed':
        return 'Tamamlandı';
      case 'extended':
        return 'Uzatıldı';
      case 'cancelled':
        return 'İptal';
      default:
        return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: onViewDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['customerName'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session['date']} ${session['time']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
              Row(
                children: [
                  Text(
                    '${session['duration']}dk',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₺${(session['earnings'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  if (session['rating'] != null) ...[
                    const Spacer(),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < (session['rating'] as int)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
