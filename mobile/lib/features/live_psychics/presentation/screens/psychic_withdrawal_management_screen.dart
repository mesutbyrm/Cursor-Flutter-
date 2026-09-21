import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicWithdrawalManagementScreen extends ConsumerStatefulWidget {
  const PsychicWithdrawalManagementScreen({super.key});

  @override
  ConsumerState<PsychicWithdrawalManagementScreen> createState() =>
      _PsychicWithdrawalManagementScreenState();
}

class _PsychicWithdrawalManagementScreenState
    extends ConsumerState<PsychicWithdrawalManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _withdrawalController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _withdrawalController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _withdrawalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CosmicGalaxyBackground(),
          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'Gelir Çekim Yönetimi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Çekimler'),
                      Tab(text: 'Bakiye'),
                      Tab(text: 'Geçmiş'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _WithdrawalsTab(controller: _withdrawalController),
                      _BalanceTab(),
                      _HistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalsTab extends StatefulWidget {
  final TextEditingController controller;

  const _WithdrawalsTab({required this.controller});

  @override
  State<_WithdrawalsTab> createState() => _WithdrawalsTabState();
}

class _WithdrawalsTabState extends State<_WithdrawalsTab> {
  String _selectedPaymentMethod = 'Banka Hesabı';

  @override
  Widget build(BuildContext context) {
    final withdrawals = [
      {
        'date': '2026-09-20',
        'amount': '₺1,500',
        'status': 'Beklemede',
        'method': 'Banka Hesabı',
        'estimatedTime': '2-3 iş günü',
        'icon': Icons.schedule_rounded,
      },
      {
        'date': '2026-09-15',
        'amount': '₺2,000',
        'status': 'Onaylandı',
        'method': 'Banka Hesabı',
        'estimatedTime': '✓ Tamamlandı',
        'icon': Icons.check_circle_rounded,
      },
      {
        'date': '2026-09-10',
        'amount': '₺1,200',
        'status': 'Başarısız',
        'method': 'E-Cüzdan',
        'estimatedTime': 'Hesap bilgisi hataı',
        'icon': Icons.error_rounded,
      },
      {
        'date': '2026-09-05',
        'amount': '₺3,000',
        'status': 'Onaylandı',
        'method': 'Banka Hesabı',
        'estimatedTime': '✓ Tamamlandı',
        'icon': Icons.check_circle_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni Çekim Talebi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çekim Tutarı',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.controller,
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Örn: 1000',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ödeme Yöntemi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey[900],
                    items: ['Banka Hesabı', 'E-Cüzdan', 'Kripto Para']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPaymentMethod = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hazırlama Ücreti',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const Text(
                      '₺5',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vergi (%10)',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const Text(
                      '₺100',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Tutar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      '₺895',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çekim talebi gönderildi'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      widget.controller.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Çekim Talebi Gönder'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Çekim Talepleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...withdrawals.map((w) {
            final isSuccess = (w['status'] as String) == 'Onaylandı';
            final isPending = (w['status'] as String) == 'Beklemede';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSuccess ? Color(0xFF66BB6A).withValues(alpha: 0.2) :
                                   isPending ? Color(0xFFFFD54F).withValues(alpha: 0.2) :
                                   Color(0xFFEF5350).withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            w['icon'] as IconData,
                            color: isSuccess ? Color(0xFF66BB6A) :
                                   isPending ? Color(0xFFFFD54F) :
                                   Color(0xFFEF5350),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    w['amount'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: isSuccess ? Color(0xFF66BB6A).withValues(alpha: 0.2) :
                                             isPending ? Color(0xFFFFD54F).withValues(alpha: 0.2) :
                                             Color(0xFFEF5350).withValues(alpha: 0.2),
                                    ),
                                    child: Text(
                                      w['status'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSuccess ? Color(0xFF66BB6A) :
                                               isPending ? Color(0xFFFFD54F) :
                                               Color(0xFFEF5350),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${w['date']} • ${w['method']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      w['estimatedTime'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Çekim talebi iptal edildi')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFFEF5350).withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'İptal Et',
                            style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BalanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesap Bakiyesi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
              ),
              color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Bakiye',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4FC3F7)),
                ),
                const SizedBox(height: 4),
                const Text(
                  '₺12,450',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4FC3F7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanılabilir',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '₺8,720',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF66BB6A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beklemede',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '₺2,150',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kilitli',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '₺1,580',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gelir Kaynakları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            {'source': 'Seans Gelirleri', 'amount': '₺8,920', 'percent': 71.6, 'icon': Icons.videocam_rounded},
            {'source': 'Hediye Bonusu', 'amount': '₺2,100', 'percent': 16.8, 'icon': Icons.card_giftcard_rounded},
            {'source': 'Referral Kazancı', 'amount': '₺980', 'percent': 7.9, 'icon': Icons.people_rounded},
            {'source': 'Diğer', 'amount': '₺450', 'percent': 3.6, 'icon': Icons.more_horiz_rounded},
          ].map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Row(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      color: AppThemeColors.accentCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['source'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (s['percent'] as double) / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppThemeColors.accentCyan,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          s['amount'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${(s['percent'] as double).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'date': '2026-09-20',
        'description': 'Seans Geliri — 2 seans',
        'type': 'Gelir',
        'amount': '+₺170',
        'icon': Icons.add_circle_rounded,
      },
      {
        'date': '2026-09-20',
        'description': 'Çekim Talebi — Banka Hesabı',
        'type': 'Çekim',
        'amount': '-₺2,000',
        'icon': Icons.remove_circle_rounded,
      },
      {
        'date': '2026-09-19',
        'description': 'Hediye Bonusu',
        'type': 'Bonus',
        'amount': '+₺50',
        'icon': Icons.card_giftcard_rounded,
      },
      {
        'date': '2026-09-18',
        'description': 'Seans Geliri — 3 seans',
        'type': 'Gelir',
        'amount': '+₺255',
        'icon': Icons.add_circle_rounded,
      },
      {
        'date': '2026-09-17',
        'description': 'Referral Kazancı',
        'type': 'Referral',
        'amount': '+₺85',
        'icon': Icons.people_rounded,
      },
      {
        'date': '2026-09-15',
        'description': 'Çekim Talebi — Banka Hesabı',
        'type': 'Çekim',
        'amount': '-₺1,500',
        'icon': Icons.remove_circle_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İşlem Geçmişi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...transactions.map((t) {
            final isIncome = (t['amount'] as String).startsWith('+');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isIncome ? Color(0xFF66BB6A).withValues(alpha: 0.2) :
                               Color(0xFFEF5350).withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        t['icon'] as IconData,
                        color: isIncome ? Color(0xFF66BB6A) : Color(0xFFEF5350),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['description'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t['date'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t['amount'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? Color(0xFF66BB6A) : Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
