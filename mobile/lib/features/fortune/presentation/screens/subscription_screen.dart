import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik Planları'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentPlanCard(context),
            const SizedBox(height: 24),
            _buildBillingToggle(),
            const SizedBox(height: 24),
            _buildPlansComparison(context),
            const SizedBox(height: 24),
            _buildFAQSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final subAsync = ref.watch(currentSubscriptionProvider);

        return subAsync.when(
          data: (sub) {
            if (sub == null) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktif Plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sub.planId.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Yenileme tarihi: ${DateFormat('d MMMM y', 'tr_TR').format(sub.currentPeriodEnd)}',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showUpgradeOptions(context, ref),
                      child: const Text('Planı Yükselt'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildBillingToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final billingCycle = ref.watch(billingCycleProvider);
                  return GestureDetector(
                    onTap: () =>
                        ref.read(billingCycleProvider.notifier).state = 'monthly',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: billingCycle == 'monthly'
                            ? Colors.cyan
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Aylık',
                          style: TextStyle(
                            color: billingCycle == 'monthly'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final billingCycle = ref.watch(billingCycleProvider);
                  return GestureDetector(
                    onTap: () =>
                        ref.read(billingCycleProvider.notifier).state = 'yearly',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: billingCycle == 'yearly'
                            ? Colors.cyan
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Yıllık',
                              style: TextStyle(
                                color: billingCycle == 'yearly'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            if (billingCycle == 'yearly')
                              Text(
                                '%17 tasarruf',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansComparison(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final plansAsync = ref.watch(subscriptionPlansProvider);

        return plansAsync.when(
          data: (plans) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: plans.map((plan) {
                  return _buildPlanCard(context, ref, plan);
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Hata: ${err.toString()}'),
        );
      },
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) {
    final billingCycle = ref.watch(billingCycleProvider);
    final price = billingCycle == 'monthly' ? plan.monthlyPrice : plan.yearlyPrice;
    final isVip = plan.planId == 'vip';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isVip ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isVip ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isVip
              ? LinearGradient(
                  colors: [Colors.amber[50]!, Colors.purple[50]!],
                )
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (plan.planId == 'premium')
                  Chip(
                    label: const Text('Popüler'),
                    backgroundColor: Colors.cyan[100],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '\$${price.toStringAsFixed(2)}/${billingCycle == 'monthly' ? 'ay' : 'yıl'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...plan.features
                .map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(feature),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVip ? Colors.amber : Colors.cyan,
                ),
                onPressed: () => _subscribePlan(context, ref, plan),
                child: Text(
                  'Abone Ol',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sıkça Sorulan Sorular',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('İstediğim zaman iptal edebilir miyim?'),
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Evet, aboneliğinizi istediğiniz zaman iptal edebilirsiniz.'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Hangi ödeme yöntemleri kabul edilir?'),
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child:
                    Text('Kredi kartı, Apple Pay ve Google Pay kabul ediyoruz.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _subscribePlan(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plan.name} planına abone olunuyor...'),
      ),
    );
  }

  void _showUpgradeOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planı Yükselt'),
        content: const Text('Premium veya VIP planına yükseltmek ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yükselt'),
          ),
        ],
      ),
    );
  }
}
