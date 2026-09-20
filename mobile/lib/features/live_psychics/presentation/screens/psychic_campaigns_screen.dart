import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Promosyon & Kampanya — Kampanya oluştur, kod, indirim, analiz.
class PsychicCampaignsScreen extends ConsumerStatefulWidget {
  const PsychicCampaignsScreen({super.key});

  @override
  ConsumerState<PsychicCampaignsScreen> createState() =>
      _PsychicCampaignsScreenState();
}

class _PsychicCampaignsScreenState extends ConsumerState<PsychicCampaignsScreen> {
  String filterStatus = 'all'; // all, active, ended

  final campaigns = [
    {
      'id': 'camp_001',
      'name': 'Yeni Müşteriler %20 İndirim',
      'code': 'YENİ20',
      'discount': 20,
      'discountType': 'percent',
      'status': 'active',
      'createdDate': '2026-09-10',
      'endDate': '2026-10-10',
      'maxUses': 100,
      'usedCount': 34,
      'revenue': 680.66,
    },
    {
      'id': 'camp_002',
      'name': 'Hafta Sonu Kampanyası',
      'code': 'HAFTA50',
      'discount': 50,
      'discountType': 'fixed',
      'status': 'active',
      'createdDate': '2026-09-01',
      'endDate': '2026-09-30',
      'maxUses': null,
      'usedCount': 12,
      'revenue': 600.00,
    },
    {
      'id': 'camp_003',
      'name': 'Sadık Müşteriler',
      'code': 'SADIK',
      'discount': 25,
      'discountType': 'percent',
      'status': 'active',
      'createdDate': '2026-08-15',
      'endDate': null,
      'maxUses': null,
      'usedCount': 156,
      'revenue': 3900.00,
    },
    {
      'id': 'camp_004',
      'name': 'Haziran Indirim Kampanyası',
      'code': 'HAZİRAN',
      'discount': 15,
      'discountType': 'percent',
      'status': 'ended',
      'createdDate': '2026-06-01',
      'endDate': '2026-06-30',
      'maxUses': 50,
      'usedCount': 50,
      'revenue': 750.00,
    },
  ];

  List<Map<String, dynamic>> _filterCampaigns() {
    if (filterStatus == 'all') return campaigns;
    return campaigns.where((c) => c['status'] == filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCampaigns();

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
                      title: 'Promosyon & Kampanya',
                      subtitle: 'Kampanya yönetimi ve analiz',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yeni kampanya oluştur ekranı açılacak'),
                          ),
                        ),
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
                              setState(() => filterStatus = 'all'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filterStatus == 'all'
                                      ? AppThemeColors.accentCyan
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Tümü (${campaigns.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: filterStatus == 'all'
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
                              setState(() => filterStatus = 'active'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filterStatus == 'active'
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Aktif (${campaigns.where((c) => c['status'] == 'active').length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: filterStatus == 'active'
                                    ? Colors.green
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
                              setState(() => filterStatus = 'ended'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filterStatus == 'ended'
                                      ? Colors.grey
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Bitti (${campaigns.where((c) => c['status'] == 'ended').length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: filterStatus == 'ended'
                                    ? Colors.grey
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campaigns
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Kampanya yok',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filtered.length, (i) {
                      final campaign = filtered[i];
                      return Column(
                        children: [
                          _CampaignCard(
                            campaign: campaign,
                            onEdit: () => _showEditDialog(context, campaign),
                            onCopy: () => _showCopyDialog(context, campaign),
                            onEnd: () => _showEndDialog(context, campaign),
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

  void _showEditDialog(BuildContext context, Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kampanya düzenleme ekranı açılacak')),
    );
  }

  void _showCopyDialog(BuildContext context, Map<String, dynamic> campaign) {
    final code = campaign['code'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kodu Kopyala'),
        content: SelectableText(code),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kodu kopyaladı')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Kopyala'),
          ),
        ],
      ),
    );
  }

  void _showEndDialog(BuildContext context, Map<String, dynamic> campaign) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kampanya Sonlandır'),
        content: Text(
          '${campaign['name']} kampanyasını sonlandırmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kampanya sonlandırıldı')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onEdit,
    required this.onCopy,
    required this.onEnd,
  });

  final Map<String, dynamic> campaign;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onEnd;

  Color _getStatusColor() {
    final status = campaign['status'] as String;
    if (status == 'active') return Colors.green;
    if (status == 'ended') return Colors.grey;
    return Colors.amber;
  }

  String _getStatusLabel() {
    final status = campaign['status'] as String;
    if (status == 'active') return 'Aktif';
    if (status == 'ended') return 'Bitti';
    return 'Bilinmiyor';
  }

  String _getDiscountLabel() {
    final discount = campaign['discount'];
    final type = campaign['discountType'] as String;
    if (type == 'percent') {
      return '%$discount';
    } else {
      return '₺$discount';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = campaign['status'] == 'active';
    final maxUses = campaign['maxUses'];
    final usedCount = campaign['usedCount'] as int;
    final endDate = campaign['endDate'] as String?;

    return Card(
      color: isActive
          ? Colors.green.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.08),
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
                      Text(
                        campaign['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kod: ${campaign['code']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'İndirim: ${_getDiscountLabel()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kullanım: $usedCount${maxUses != null ? '/$maxUses' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Gelir: ₺${(campaign['revenue'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                if (endDate != null)
                  Text(
                    'Bitiş: $endDate',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.content_copy_rounded, size: 14),
                  label: const Text('Kod'),
                  onPressed: onCopy,
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Düzenle'),
                  onPressed: onEdit,
                ),
                if (isActive)
                  const SizedBox(width: 4),
                if (isActive)
                  TextButton.icon(
                    icon: const Icon(Icons.stop_circle_rounded, size: 14),
                    label: const Text('Sonlandır'),
                    onPressed: onEnd,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
