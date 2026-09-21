import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Flash Sales — Belirli saatlerde indirimli seans sunma
class PsychicFlashSalesScreen extends ConsumerStatefulWidget {
  const PsychicFlashSalesScreen({super.key});

  @override
  ConsumerState<PsychicFlashSalesScreen> createState() =>
      _PsychicFlashSalesScreenState();
}

class _PsychicFlashSalesScreenState
    extends ConsumerState<PsychicFlashSalesScreen> {
  final List<Map<String, dynamic>> flashSales = [
    {
      'id': 'flash_001',
      'title': 'Pazartesi Özel Seansı',
      'day': 'Pazartesi',
      'startTime': '18:00',
      'endTime': '20:00',
      'duration': 30,
      'discount': 20,
      'normalPrice': 100,
      'salePrice': 80,
      'slots': 3,
      'bookedSlots': 2,
      'status': 'active',
      'createdDate': '2025-02-01',
      'notifyFollowers': true,
    },
    {
      'id': 'flash_002',
      'title': 'Perşembe Romantizm',
      'day': 'Perşembe',
      'startTime': '20:00',
      'endTime': '22:00',
      'duration': 45,
      'discount': 15,
      'normalPrice': 150,
      'salePrice': 128,
      'slots': 4,
      'bookedSlots': 1,
      'status': 'active',
      'createdDate': '2025-02-03',
      'notifyFollowers': true,
    },
    {
      'id': 'flash_003',
      'title': 'Cuma Kariyer Danışmanlığı',
      'day': 'Cuma',
      'startTime': '19:00',
      'endTime': '21:00',
      'duration': 30,
      'discount': 25,
      'normalPrice': 100,
      'salePrice': 75,
      'slots': 5,
      'bookedSlots': 5,
      'status': 'full',
      'createdDate': '2025-02-05',
      'notifyFollowers': true,
    },
    {
      'id': 'flash_004',
      'title': 'Pazar Sağlık & Wellness',
      'day': 'Pazar',
      'startTime': '10:00',
      'endTime': '12:00',
      'duration': 30,
      'discount': 10,
      'normalPrice': 100,
      'salePrice': 90,
      'slots': 2,
      'bookedSlots': 0,
      'status': 'draft',
      'createdDate': '2025-02-07',
      'notifyFollowers': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeSales = flashSales.where((s) => s['status'] == 'active').toList();
    final fullSales = flashSales.where((s) => s['status'] == 'full').toList();
    final draftSales = flashSales.where((s) => s['status'] == 'draft').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Flash Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateFlashSaleDialog,
          ),
        ],
      ),
      body: DiscoverBackground(
        child: DiscoverTabLayout(
          tabs: const ['Aktif', 'Dolu', 'Taslak'],
          children: [
            // Aktif Flash Sales
            if (activeSales.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aktif flash sale yok',
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
                itemCount: activeSales.length,
                itemBuilder: (context, index) {
                  final sale = activeSales[index];
                  return _FlashSaleCard(
                    sale: sale,
                    onEdit: () => _showEditFlashSaleDialog(sale),
                    onEnd: () => _endFlashSale(sale['id']),
                  );
                },
              ),
            // Dolu Flash Sales
            if (fullSales.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dolu flash sale yok',
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
                itemCount: fullSales.length,
                itemBuilder: (context, index) {
                  final sale = fullSales[index];
                  return _FlashSaleCard(
                    sale: sale,
                    isFull: true,
                  );
                },
              ),
            // Taslak Flash Sales
            if (draftSales.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Taslak flash sale yok',
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
                itemCount: draftSales.length,
                itemBuilder: (context, index) {
                  final sale = draftSales[index];
                  return _FlashSaleCard(
                    sale: sale,
                    isDraft: true,
                    onPublish: () => _publishFlashSale(sale['id']),
                    onDelete: () => _deleteFlashSale(sale['id']),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateFlashSaleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _FlashSaleDialog(
        onSave: (data) {
          setState(() {
            flashSales.insert(0, {
              'id': 'flash_${DateTime.now().millisecondsSinceEpoch}',
              'title': data['title'],
              'day': data['day'],
              'startTime': data['startTime'],
              'endTime': data['endTime'],
              'duration': data['duration'],
              'discount': data['discount'],
              'normalPrice': data['normalPrice'],
              'salePrice': data['salePrice'],
              'slots': data['slots'],
              'bookedSlots': 0,
              'status': 'draft',
              'createdDate': DateTime.now().toString().split(' ')[0],
              'notifyFollowers': true,
            });
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flash sale taslağı oluşturuldu: ${data['title']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showEditFlashSaleDialog(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (ctx) => _FlashSaleDialog(
        sale: sale,
        onSave: (data) {
          setState(() {
            final idx = flashSales.indexWhere((s) => s['id'] == sale['id']);
            if (idx >= 0) {
              flashSales[idx] = {
                ...flashSales[idx],
                'title': data['title'],
                'day': data['day'],
                'startTime': data['startTime'],
                'endTime': data['endTime'],
                'duration': data['duration'],
                'discount': data['discount'],
                'normalPrice': data['normalPrice'],
                'salePrice': data['salePrice'],
                'slots': data['slots'],
              };
            }
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flash sale güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _publishFlashSale(String saleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flash Sale\'i Yayınla?'),
        content: const Text(
          'Takipçilerine bildirim gönderilecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = flashSales.indexWhere((s) => s['id'] == saleId);
                if (idx >= 0) {
                  flashSales[idx]['status'] = 'active';
                  flashSales[idx]['notifyFollowers'] = true;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flash sale yayınlandı ve takipçiler bilgilendirildi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Yayınla'),
          ),
        ],
      ),
    );
  }

  void _endFlashSale(String saleId) {
    setState(() {
      final idx = flashSales.indexWhere((s) => s['id'] == saleId);
      if (idx >= 0) {
        flashSales.removeAt(idx);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flash sale sonlandırıldı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteFlashSale(String saleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taslağı Sil?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                flashSales.removeWhere((s) => s['id'] == saleId);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Taslak silindi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({
    required this.sale,
    this.onEdit,
    this.onEnd,
    this.onPublish,
    this.onDelete,
    this.isFull = false,
    this.isDraft = false,
  });

  final Map<String, dynamic> sale;
  final VoidCallback? onEdit;
  final VoidCallback? onEnd;
  final VoidCallback? onPublish;
  final VoidCallback? onDelete;
  final bool isFull;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final fillPercentage =
        (sale['bookedSlots'] as int) / (sale['slots'] as int) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isFull
                ? Colors.green.withValues(alpha: 0.2)
                : isDraft
                    ? Colors.orange.withValues(alpha: 0.2)
                    : AppThemeColors.accentCyan.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sale['day']} · ${sale['startTime']}-${sale['endTime']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Dolu',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (isDraft)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Taslak',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sale['duration']} dakika',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%${sale['discount']} indirim',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${sale['normalPrice']} jeton',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '${sale['salePrice']} jeton',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slotlar: ${sale['bookedSlots']}/${sale['slots']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${fillPercentage.toStringAsFixed(0)}% dolu',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercentage / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isFull ? Colors.green : AppThemeColors.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isDraft && !isFull && onEdit != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Düzenle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isDraft && onEnd != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEnd,
                      icon: const Icon(Icons.close_outlined, size: 14),
                      label: const Text('Sonlandır'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  )
                else if (isDraft && onPublish != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.icon(
                        onPressed: onPublish,
                        icon: const Icon(Icons.publish_outlined, size: 14),
                        label: const Text('Yayınla'),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppThemeColors.accentCyan,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isDraft && onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
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

class _FlashSaleDialog extends StatefulWidget {
  const _FlashSaleDialog({
    this.sale,
    required this.onSave,
  });

  final Map<String, dynamic>? sale;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<_FlashSaleDialog> createState() => _FlashSaleDialogState();
}

class _FlashSaleDialogState extends State<_FlashSaleDialog> {
  late TextEditingController titleController;
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late TextEditingController durationController;
  late TextEditingController discountController;
  late TextEditingController normalPriceController;
  late TextEditingController slotsController;

  String selectedDay = 'Pazartesi';

  final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    titleController = TextEditingController(text: sale?['title'] ?? '');
    startTimeController = TextEditingController(text: sale?['startTime'] ?? '18:00');
    endTimeController = TextEditingController(text: sale?['endTime'] ?? '20:00');
    durationController = TextEditingController(
      text: (sale?['duration'] ?? 30).toString(),
    );
    discountController = TextEditingController(
      text: (sale?['discount'] ?? 20).toString(),
    );
    normalPriceController = TextEditingController(
      text: (sale?['normalPrice'] ?? 100).toString(),
    );
    slotsController = TextEditingController(
      text: (sale?['slots'] ?? 3).toString(),
    );
    selectedDay = sale?['day'] ?? 'Pazartesi';
  }

  @override
  void dispose() {
    titleController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    durationController.dispose();
    discountController.dispose();
    normalPriceController.dispose();
    slotsController.dispose();
    super.dispose();
  }

  double get salePrice {
    final normal = double.tryParse(normalPriceController.text) ?? 0;
    final discount = double.tryParse(discountController.text) ?? 0;
    return normal * (1 - discount / 100);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sale == null ? 'Yeni Flash Sale' : 'Flash Sale\'i Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
                hintText: 'ör. Pazartesi Özel Seansı',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: const InputDecoration(
                labelText: 'Gün',
                border: OutlineInputBorder(),
              ),
              items: days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value ?? 'Pazartesi';
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Başlama',
                      border: OutlineInputBorder(),
                      hintText: '18:00',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Bitiş',
                      border: OutlineInputBorder(),
                      hintText: '20:00',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Dakika',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: slotsController,
                    decoration: const InputDecoration(
                      labelText: 'Slot Sayısı',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: normalPriceController,
              decoration: const InputDecoration(
                labelText: 'Normal Fiyat (jeton)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'İndirim %',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Son Fiyat:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${salePrice.toStringAsFixed(0)} jeton',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave({
              'title': titleController.text,
              'day': selectedDay,
              'startTime': startTimeController.text,
              'endTime': endTimeController.text,
              'duration': int.tryParse(durationController.text) ?? 30,
              'discount': double.tryParse(discountController.text) ?? 20,
              'normalPrice': double.tryParse(normalPriceController.text) ?? 100,
              'salePrice': salePrice,
              'slots': int.tryParse(slotsController.text) ?? 3,
            });
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
