import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Müşteri yönetimi — Sık danışanlar ve engellenen müşteriler
class PsychicCustomersScreen extends ConsumerStatefulWidget {
  const PsychicCustomersScreen({super.key});

  @override
  ConsumerState<PsychicCustomersScreen> createState() =>
      _PsychicCustomersScreenState();
}

class _PsychicCustomersScreenState
    extends ConsumerState<PsychicCustomersScreen> {
  final List<Map<String, dynamic>> customers = [
    {
      'id': 'cust_001',
      'name': 'Aylin Şahin',
      'avatar': '👩',
      'lastSession': '2025-02-15 14:30',
      'totalSessions': 8,
      'totalSpent': 480,
      'rating': 5,
      'isBlocked': false,
      'notes': 'Aşk konusu özel ilgi. Hızlı karar veren müşteri.',
    },
    {
      'id': 'cust_002',
      'name': 'Mehmet Yılmaz',
      'avatar': '👨',
      'lastSession': '2025-02-10 10:15',
      'totalSessions': 5,
      'totalSpent': 220,
      'rating': 4,
      'isBlocked': false,
      'notes': 'Kariyer danışmanlığı. Sabırlı, detaylı sorular soruyor.',
    },
    {
      'id': 'cust_003',
      'name': 'Elif Kara',
      'avatar': '👩',
      'lastSession': '2025-02-05 18:45',
      'totalSessions': 12,
      'totalSpent': 720,
      'rating': 5,
      'isBlocked': false,
      'notes': 'En sık danışan. Haftalık seans istiyor.',
    },
    {
      'id': 'cust_004',
      'name': 'Veli Demir',
      'avatar': '👨',
      'lastSession': '2024-12-01 16:20',
      'totalSessions': 2,
      'totalSpent': 100,
      'rating': 2,
      'isBlocked': true,
      'notes': 'Uygunsuz davranış. Seans sırasında müstehcen soru sordu.',
    },
    {
      'id': 'cust_005',
      'name': 'Zara Hasan',
      'avatar': '👩',
      'lastSession': '2025-02-12 09:00',
      'totalSessions': 3,
      'totalSpent': 150,
      'rating': 5,
      'isBlocked': false,
      'notes': 'Yeni müşteri. Seans paketiyle başladı.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final frequentCustomers =
        customers.where((c) => !c['isBlocked']).toList();
    final blockedCustomers =
        customers.where((c) => c['isBlocked']).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Müşteriler'),
      ),
      body: DiscoverBackground(
        child: DiscoverTabLayout(
          tabs: const ['Sık Danışanlar', 'Engellenen'],
          children: [
            // Sık Danışanlar
            if (frequentCustomers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz müşteri yok',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                itemCount: frequentCustomers.length,
                itemBuilder: (context, index) {
                  final customer = frequentCustomers[index];
                  return _CustomerCard(
                    customer: customer,
                    onBlock: () => _blockCustomer(customer['id']),
                    onEditNotes: () => _showNotesDialog(customer),
                    onMessage: () =>
                        _showMessageDialog(customer['name']),
                  );
                },
              ),
            // Engellenen Müşteriler
            if (blockedCustomers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Engellenen müşteri yok',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                itemCount: blockedCustomers.length,
                itemBuilder: (context, index) {
                  final customer = blockedCustomers[index];
                  return _CustomerCard(
                    customer: customer,
                    isBlocked: true,
                    onUnblock: () => _unblockCustomer(customer['id']),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _blockCustomer(String customerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müşteri Engelle?'),
        content: const Text(
          'Bu müşteri sizin listelerinde göremez ve seans talebinde bulunamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = customers.indexWhere((c) => c['id'] == customerId);
                if (idx >= 0) {
                  customers[idx]['isBlocked'] = true;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Müşteri engellendi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  void _unblockCustomer(String customerId) {
    setState(() {
      final idx = customers.indexWhere((c) => c['id'] == customerId);
      if (idx >= 0) {
        customers[idx]['isBlocked'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Müşteri kaldırıldı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotesDialog(Map<String, dynamic> customer) {
    final notesController = TextEditingController(text: customer['notes']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${customer['name']} Notları'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Müşteri hakkında notlar...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = customers
                    .indexWhere((c) => c['id'] == customer['id']);
                if (idx >= 0) {
                  customers[idx]['notes'] = notesController.text;
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

  void _showMessageDialog(String customerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$customerName\'a mesaj gönderi (hazırlanıyor)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onBlock,
    this.onEditNotes,
    this.onMessage,
    this.onUnblock,
    this.isBlocked = false,
  });

  final Map<String, dynamic> customer;
  final VoidCallback onBlock;
  final VoidCallback? onEditNotes;
  final VoidCallback? onMessage;
  final VoidCallback? onUnblock;
  final bool isBlocked;

  @override
  Widget build(BuildContext context) {
    final rating = customer['rating'] as int?;
    final ratingStars = rating != null ? '★' * rating : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isBlocked
                ? Colors.red.withValues(alpha: 0.2)
                : AppThemeColors.accentCyan.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      customer['avatar'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Son seans: ${customer['lastSession']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Engellendi',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isBlocked) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam: ${customer['totalSessions']} seans',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        'Harcama: ${customer['totalSpent']} jeton',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ratingStars,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        '${customer['rating']}/5',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer['notes'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditNotes,
                      icon: const Icon(Icons.note_outlined, size: 14),
                      label: const Text('Notlar'),
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
                      onPressed: onMessage,
                      icon: const Icon(Icons.message_outlined, size: 14),
                      label: const Text('Mesaj'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onBlock,
                    icon: const Icon(Icons.block_outlined, size: 14),
                    label: const Text('Engelle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (onUnblock != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUnblock,
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Engeli Kaldır'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
