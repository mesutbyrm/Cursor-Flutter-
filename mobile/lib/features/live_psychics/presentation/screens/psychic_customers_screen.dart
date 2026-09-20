import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Müşteri Yönetimi — Sık müşteriler, blok listesi, notlar.
class PsychicCustomersScreen extends ConsumerStatefulWidget {
  const PsychicCustomersScreen({super.key});

  @override
  ConsumerState<PsychicCustomersScreen> createState() =>
      _PsychicCustomersScreenState();
}

class _PsychicCustomersScreenState extends ConsumerState<PsychicCustomersScreen> {
  String filterTab = 'frequent'; // frequent, blocked

  final customers = [
    {
      'id': 'cust_001',
      'name': 'Aylin Şahin',
      'avatar': '👩',
      'sessions': 12,
      'totalSpent': 588.00,
      'lastSession': '2 gün önce',
      'isFrequent': true,
      'isBlocked': false,
      'notes': 'Çok memnun müşteri, düzenli geliyor',
      'joinDate': '2025-06-15',
    },
    {
      'id': 'cust_002',
      'name': 'Mehmet Kaya',
      'avatar': '👨',
      'sessions': 8,
      'totalSpent': 392.00,
      'lastSession': '1 hafta önce',
      'isFrequent': true,
      'isBlocked': false,
      'notes': 'Her seans sonunda sorular soruyor',
      'joinDate': '2025-07-20',
    },
    {
      'id': 'cust_003',
      'name': 'Fatma Yüksek',
      'avatar': '👵',
      'sessions': 5,
      'totalSpent': 245.00,
      'lastSession': '3 hafta önce',
      'isFrequent': true,
      'isBlocked': false,
      'notes': 'Yaşlı müşteri, sabırlı olmalısın',
      'joinDate': '2025-08-10',
    },
    {
      'id': 'cust_004',
      'name': 'Emre Demir',
      'avatar': '👨',
      'sessions': 1,
      'totalSpent': 49.99,
      'lastSession': '2 ay önce',
      'isFrequent': false,
      'isBlocked': true,
      'notes': 'Uygunsuz davranış',
      'blockDate': '2025-07-15',
    },
    {
      'id': 'cust_005',
      'name': 'Zeynep Arslan',
      'avatar': '👩',
      'sessions': 1,
      'totalSpent': 49.99,
      'lastSession': '1 ay önce',
      'isFrequent': false,
      'isBlocked': true,
      'notes': 'Şüpheli ödeme davranışı',
      'blockDate': '2025-08-01',
    },
  ];

  List<Map<String, dynamic>> _filterCustomers() {
    if (filterTab == 'frequent') {
      return customers
          .where((c) => (c['isFrequent'] as bool) && !(c['isBlocked'] as bool))
          .toList();
    } else {
      return customers.where((c) => c['isBlocked'] as bool).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCustomers();

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
                      title: 'Müşteri Yönetimi',
                      subtitle: 'Müşteri listesi ve blok yönetimi',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.search_rounded,
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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => filterTab = 'frequent'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filterTab == 'frequent'
                                      ? AppThemeColors.accentCyan
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Sık Müşteriler (${customers.where((c) => (c['isFrequent'] as bool) && !(c['isBlocked'] as bool)).length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: filterTab == 'frequent'
                                    ? AppThemeColors.accentCyan
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => filterTab = 'blocked'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filterTab == 'blocked'
                                      ? Colors.red
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Engellenenler (${customers.where((c) => c['isBlocked'] as bool).length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: filterTab == 'blocked'
                                    ? Colors.red
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer list
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          filterTab == 'frequent'
                              ? 'Henüz sık müşteri yok'
                              : 'Hiç kimse engellenmedi',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filtered.length, (i) {
                      final customer = filtered[i];
                      return Column(
                        children: [
                          _CustomerCard(
                            customer: customer,
                            onAddNote: () =>
                                _showNoteDialog(context, customer),
                            onBlock: () => _showBlockConfirm(context, customer),
                            onUnblock: () =>
                                _showUnblockConfirm(context, customer),
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

  void _showNoteDialog(BuildContext context, Map<String, dynamic> customer) {
    final noteCtrl = TextEditingController(
      text: customer['notes'] as String? ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Not Ekle — ${customer['name']}'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Not yazın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not kaydedildi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirm(BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müşteri Engelle'),
        content: Text(
          '${customer['name']} sizin seanslarınıza erişemez. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Müşteri engellendi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirm(
      BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Engeli Kaldır'),
        content: Text(
          '${customer['name']} seanslarınızı rezerve edebilir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Engel kaldırıldı')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onAddNote,
    required this.onBlock,
    required this.onUnblock,
  });

  final Map<String, dynamic> customer;
  final VoidCallback onAddNote;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final isBlocked = customer['isBlocked'] as bool;

    return Card(
      color: isBlocked
          ? Colors.red.withValues(alpha: 0.1)
          : AppThemeColors.accentCyan.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  customer['avatar'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Son seans: ${customer['lastSession']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
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
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Engellendi',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!isBlocked) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${customer['sessions']} seans',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₺${(customer['totalSpent'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isBlocked)
                  Expanded(
                    child: Text(
                      'Engel tarihi: ${customer['blockDate']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if ((customer['notes'] as String?)?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Not:',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer['notes'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isBlocked)
                  TextButton.icon(
                    icon: const Icon(Icons.note_add_outlined, size: 14),
                    label: const Text('Not'),
                    onPressed: onAddNote,
                  ),
                const SizedBox(width: 4),
                if (!isBlocked)
                  TextButton.icon(
                    icon: const Icon(Icons.block_rounded, size: 14),
                    label: const Text('Engelle'),
                    onPressed: onBlock,
                  ),
                if (isBlocked)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 14),
                    label: const Text('Engeli Kaldır'),
                    onPressed: onUnblock,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
