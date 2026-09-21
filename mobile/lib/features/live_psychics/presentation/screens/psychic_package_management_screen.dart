import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Seans paketleri — Falcı: "3 seans %15 indirim" yaratabilir, müşteri: paketli satın alabilir
class PsychicPackageManagementScreen extends ConsumerStatefulWidget {
  const PsychicPackageManagementScreen({super.key});

  @override
  ConsumerState<PsychicPackageManagementScreen> createState() =>
      _PsychicPackageManagementScreenState();
}

class _PsychicPackageManagementScreenState
    extends ConsumerState<PsychicPackageManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> packages = [
    {
      'id': 'pkg_001',
      'name': 'Aşk Paketı',
      'description': '3 seans, aşk ve ilişkiler odağında',
      'sessionCount': 3,
      'durationPerSession': 30,
      'discountType': 'percent',
      'discountValue': 15,
      'originalPrice': 300,
      'finalPrice': 255,
      'currency': 'jeton',
      'createdDate': '2025-02-01',
      'status': 'active',
      'useCount': 8,
    },
    {
      'id': 'pkg_002',
      'name': 'Kariyer Danışmanlığı',
      'description': '5 seans, kariyer ve iş gelişimi',
      'sessionCount': 5,
      'durationPerSession': 45,
      'discountType': 'percent',
      'discountValue': 20,
      'originalPrice': 625,
      'finalPrice': 500,
      'currency': 'jeton',
      'createdDate': '2025-02-05',
      'status': 'active',
      'useCount': 5,
    },
    {
      'id': 'pkg_003',
      'name': 'Sağlık & Wellness',
      'description': '4 seans, ruh sağlığı ve wellness',
      'sessionCount': 4,
      'durationPerSession': 30,
      'discountType': 'fixed',
      'discountValue': 50,
      'originalPrice': 320,
      'finalPrice': 270,
      'currency': 'jeton',
      'createdDate': '2025-02-10',
      'status': 'ended',
      'useCount': 12,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePackages =
        packages.where((p) => p['status'] == 'active').toList();
    final endedPackages =
        packages.where((p) => p['status'] == 'ended').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Seans Paketleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreatePackageDialog,
          ),
        ],
      ),
      body: DiscoverBackground(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Aktif'),
                Tab(text: 'Sonlandırılmış'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
            // Aktif Paketler
            if (activePackages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz paket yok',
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
                itemCount: activePackages.length,
                itemBuilder: (context, index) {
                  final pkg = activePackages[index];
                  return _PackageCard(
                    package: pkg,
                    onEdit: () => _showEditPackageDialog(pkg),
                    onEnd: () => _endPackage(pkg['id']),
                  );
                },
              ),
            // Sonlandırılmış Paketler
            if (endedPackages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sonlandırılmış paket yok',
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
                itemCount: endedPackages.length,
                itemBuilder: (context, index) {
                  final pkg = endedPackages[index];
                  return _PackageCard(
                    package: pkg,
                    isEnded: true,
                    onEdit: () => _showEditPackageDialog(pkg),
                    onReactivate: () => _reactivatePackage(pkg['id']),
                  );
                },
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePackageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _PackageDialog(
        onSave: (data) {
          setState(() {
            packages.insert(0, {
              'id': 'pkg_${DateTime.now().millisecondsSinceEpoch}',
              'name': data['name'],
              'description': data['description'],
              'sessionCount': data['sessionCount'],
              'durationPerSession': data['durationPerSession'],
              'discountType': data['discountType'],
              'discountValue': data['discountValue'],
              'originalPrice': data['originalPrice'],
              'finalPrice': data['finalPrice'],
              'currency': 'jeton',
              'createdDate':
                  DateTime.now().toString().split(' ')[0],
              'status': 'active',
              'useCount': 0,
            });
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paket oluşturuldu: ${data['name']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showEditPackageDialog(Map<String, dynamic> pkg) {
    showDialog(
      context: context,
      builder: (ctx) => _PackageDialog(
        package: pkg,
        onSave: (data) {
          setState(() {
            final idx = packages.indexWhere((p) => p['id'] == pkg['id']);
            if (idx >= 0) {
              packages[idx] = {
                ...packages[idx],
                'name': data['name'],
                'description': data['description'],
                'sessionCount': data['sessionCount'],
                'durationPerSession': data['durationPerSession'],
                'discountType': data['discountType'],
                'discountValue': data['discountValue'],
                'originalPrice': data['originalPrice'],
                'finalPrice': data['finalPrice'],
              };
            }
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paket güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _endPackage(String pkgId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paketi Sonlandır?'),
        content: const Text(
          'Bu paket artık müşterilere sunulmayacak. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = packages.indexWhere((p) => p['id'] == pkgId);
                if (idx >= 0) {
                  packages[idx]['status'] = 'ended';
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paket sonlandırıldı'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
  }

  void _reactivatePackage(String pkgId) {
    setState(() {
      final idx = packages.indexWhere((p) => p['id'] == pkgId);
      if (idx >= 0) {
        packages[idx]['status'] = 'active';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paket yeniden aktifleştirildi'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.onEdit,
    this.onEnd,
    this.onReactivate,
    this.isEnded = false,
  });

  final Map<String, dynamic> package;
  final VoidCallback onEdit;
  final VoidCallback? onEnd;
  final VoidCallback? onReactivate;
  final bool isEnded;

  @override
  Widget build(BuildContext context) {
    final discountLabel = package['discountType'] == 'percent'
        ? '%${package['discountValue']}'
        : '${package['discountValue']} jeton';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isEnded
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isEnded)
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
                      'Sonlandı',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
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
                      '${package['sessionCount']} Seans',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${package['durationPerSession']} dakika',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
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
                        '${package['originalPrice']} jeton',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '${package['finalPrice']} jeton',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İndirim: $discountLabel',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kullanım: ${package['useCount']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  children: [
                    if (!isEnded)
                      Padding(
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
                    if (!isEnded && onEnd != null)
                      OutlinedButton.icon(
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
                      )
                    else if (isEnded && onReactivate != null)
                      OutlinedButton.icon(
                        onPressed: onReactivate,
                        icon: const Icon(Icons.refresh_outlined, size: 14),
                        label: const Text('Aktifleştir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageDialog extends StatefulWidget {
  const _PackageDialog({
    this.package,
    required this.onSave,
  });

  final Map<String, dynamic>? package;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController sessionCountController;
  late TextEditingController durationController;
  late TextEditingController discountValueController;
  late TextEditingController originalPriceController;

  String selectedDiscountType = 'percent';

  @override
  void initState() {
    super.initState();
    final pkg = widget.package;
    nameController = TextEditingController(text: pkg?['name'] ?? '');
    descriptionController =
        TextEditingController(text: pkg?['description'] ?? '');
    sessionCountController = TextEditingController(
      text: (pkg?['sessionCount'] ?? 3).toString(),
    );
    durationController = TextEditingController(
      text: (pkg?['durationPerSession'] ?? 30).toString(),
    );
    discountValueController = TextEditingController(
      text: (pkg?['discountValue'] ?? 15).toString(),
    );
    originalPriceController = TextEditingController(
      text: (pkg?['originalPrice'] ?? 300).toString(),
    );
    selectedDiscountType = pkg?['discountType'] ?? 'percent';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    sessionCountController.dispose();
    durationController.dispose();
    discountValueController.dispose();
    originalPriceController.dispose();
    super.dispose();
  }

  double get finalPrice {
    final original = double.tryParse(originalPriceController.text) ?? 0;
    final discount = double.tryParse(discountValueController.text) ?? 0;
    if (selectedDiscountType == 'percent') {
      return original * (1 - discount / 100);
    } else {
      return original - discount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.package == null ? 'Yeni Paket' : 'Paketi Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Paket Adı',
                border: OutlineInputBorder(),
                hintText: 'ör. Aşk Paketı',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
                hintText: 'ör. 3 seans, aşk ve ilişkiler odağında',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sessionCountController,
                    decoration: const InputDecoration(
                      labelText: 'Seans Sayısı',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: originalPriceController,
              decoration: const InputDecoration(
                labelText: 'Orijinal Fiyat (jeton)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDiscountType,
                    decoration: const InputDecoration(
                      labelText: 'İndirim Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'percent', child: Text('%')),
                      DropdownMenuItem(value: 'fixed', child: Text('Sabit')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDiscountType = value ?? 'percent';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: discountValueController,
                    decoration: InputDecoration(
                      labelText: selectedDiscountType == 'percent'
                          ? 'İndirim %'
                          : 'İndirim Miktarı',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
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
                    '${finalPrice.toStringAsFixed(0)} jeton',
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
              'name': nameController.text,
              'description': descriptionController.text,
              'sessionCount': int.tryParse(sessionCountController.text) ?? 3,
              'durationPerSession':
                  int.tryParse(durationController.text) ?? 30,
              'discountType': selectedDiscountType,
              'discountValue': double.tryParse(discountValueController.text) ?? 15,
              'originalPrice':
                  double.tryParse(originalPriceController.text) ?? 300,
              'finalPrice': finalPrice,
            });
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
