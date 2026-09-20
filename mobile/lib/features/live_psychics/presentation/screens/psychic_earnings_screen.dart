import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Kazanç Yönetimi — Cüzdan, çekme talepleri, ödeme yöntemi.
class PsychicEarningsScreen extends ConsumerWidget {
  const PsychicEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock earnings data
    final walletBalance = 3450.75;
    final pendingBalance = 520.00;
    final totalEarned = 12450.75;

    final withdrawals = [
      {
        'id': 'wd_001',
        'amount': 1000.00,
        'method': 'Banka Transferi',
        'date': '2026-09-18',
        'status': 'completed', // completed, pending, failed
        'account': 'Ziraat Bankası (****1234)',
      },
      {
        'id': 'wd_002',
        'amount': 500.00,
        'method': 'IBAN Transfer',
        'date': '2026-09-15',
        'status': 'completed',
        'account': 'Garanti Bankası (****5678)',
      },
      {
        'id': 'wd_003',
        'amount': 750.00,
        'method': 'Banka Transferi',
        'date': '2026-09-10',
        'status': 'pending',
        'account': 'İş Bankası (****9012)',
      },
      {
        'id': 'wd_004',
        'amount': 1200.00,
        'method': 'PayPal',
        'date': '2026-09-05',
        'status': 'failed',
        'account': 'paypal@example.com',
      },
    ];

    const paymentMethods = [
      {
        'id': 'pm_001',
        'type': 'Banka Transferi',
        'account': 'Ziraat Bankası (****1234)',
        'owner': 'Ayşe Kaya',
        'isDefault': true,
      },
      {
        'id': 'pm_002',
        'type': 'IBAN Transfer',
        'account': 'Garanti Bankası (****5678)',
        'owner': 'Ayşe Kaya',
        'isDefault': false,
      },
      {
        'id': 'pm_003',
        'type': 'PayPal',
        'account': 'paypal@example.com',
        'owner': 'Ayşe Kaya',
        'isDefault': false,
      },
    ];

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
                      title: 'Kazanç Yönetimi',
                      subtitle: 'Cüzdan, çekme, ödeme yöntemi',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.help_outline_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Wallet balance card
                  Card(
                    color: Colors.green.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cüzdan Bakiyesi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₺${walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Çekmeyi Bekleyen: ₺${pendingBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Toplam Kazanılan: ₺${totalEarned.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.money_rounded),
                              label: const Text('Para Çek'),
                              onPressed: () {
                                _showWithdrawDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment methods
                  const Text(
                    'Ödeme Yöntemleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    paymentMethods.length,
                    (i) {
                      final method = paymentMethods[i];
                      return _PaymentMethodCard(
                        method: method,
                        onEdit: () => _showEditPaymentDialog(context, method),
                        onDelete: () => _showDeleteConfirm(context),
                        onSetDefault: () {},
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ödeme Yöntemi Ekle'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ödeme yöntemi ekleme ekranı açılacak'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Withdrawal history
                  const Text(
                    'Çekme Geçmişi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    withdrawals.length,
                    (i) {
                      final withdrawal = withdrawals[i];
                      return _WithdrawalCard(
                        id: withdrawal['id'] as String,
                        amount: withdrawal['amount'] as double,
                        method: withdrawal['method'] as String,
                        date: withdrawal['date'] as String,
                        status: withdrawal['status'] as String,
                        account: withdrawal['account'] as String,
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

  void _showWithdrawDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    String selectedMethod = 'pm_001';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Para Çek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Çekme tutarı (₺)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ödeme Yöntemi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              value: selectedMethod,
              items: [
                'pm_001',
                'pm_002',
                'pm_003',
              ]
                  .map((id) => DropdownMenuItem(
                        value: id,
                        child: Text('Yöntem $id'),
                      ))
                  .toList(),
              onChanged: (val) {},
              decoration: const InputDecoration(
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
                const SnackBar(content: Text('Çekme talebiniz gönderildi')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Çek'),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, Map<String, dynamic> method) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ödeme yöntemi düzenle ekranı açılacak')),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu ödeme yöntemi silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ödeme yöntemi silindi')),
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

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Map<String, dynamic> method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (method['isDefault'] as bool)
          ? AppThemeColors.accentCyan.withValues(alpha: 0.12)
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
                        method['type'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method['account'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'İçinde: ${method['owner']}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (method['isDefault'] as bool)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Varsayılan',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.accentCyan,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Düzenle'),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                if (!(method['isDefault'] as bool))
                  TextButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Varsayılan Yap'),
                    onPressed: onSetDefault,
                  ),
                if (!(method['isDefault'] as bool))
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
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({
    required this.id,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
    required this.account,
  });

  final String id;
  final double amount;
  final String method;
  final String date;
  final String status;
  final String account;

  Color _getStatusColor() {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'failed':
        return 'Başarısız';
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
                        '₺${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              account,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
