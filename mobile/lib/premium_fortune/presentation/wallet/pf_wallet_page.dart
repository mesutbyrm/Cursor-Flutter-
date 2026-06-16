import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_wallet.dart';
import '../wallet/pf_wallet_view_model.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

class PfWalletPage extends ConsumerStatefulWidget {
  const PfWalletPage({super.key});

  @override
  ConsumerState<PfWalletPage> createState() => _PfWalletPageState();
}

class _PfWalletPageState extends ConsumerState<PfWalletPage> {
  final _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(pfEffectiveUserProvider);
    final credits = user != null
        ? ref.watch(pfCreditsProvider(user.id)).valueOrNull ?? user.credits
        : 0;
    final tx = ref.watch(pfWalletViewModelProvider);
    final vm = ref.read(pfWalletViewModelProvider.notifier);
    final packages = vm.packages;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Sanal Cüzdan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: PfGlassCard(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1650), Color(0xFF1A0E38)],
              ),
              child: Column(
                children: [
                  const Text('Bakiyeniz',
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Text(
                    '$credits',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: PfTheme.gold,
                    ),
                  ),
                  const Text('kredi',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const PfSectionHeader(title: 'Kredi Paketleri'),
          ...packages.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: PfGlassCard(
                onTap: () async {
                  final err = await vm.purchasePackage(p);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? '${p.totalCredits} kredi eklendi!'),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${p.totalCredits} Kredi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (p.isPopular) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PfTheme.pink.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Popüler',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (p.bonusCredits > 0)
                            Text(
                              '+${p.bonusCredits} bonus',
                              style: const TextStyle(
                                color: PfTheme.gold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      p.priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: PfTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Kupon kodu',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final err = await vm.redeemCoupon(_couponCtrl.text);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err ?? 'Kupon uygulandı!')),
                    );
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          const PfSectionHeader(title: 'İşlem Geçmişi'),
          tx.when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Henüz işlem yok',
                        style: TextStyle(color: Colors.white54)),
                  )
                : Column(
                    children: items.map((t) => _TxTile(tx: t)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});

  final PfWalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.amount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: PfGlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description),
                  Text(
                    '${tx.createdAt.day}.${tx.createdAt.month}.${tx.createdAt.year}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${tx.amount}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
