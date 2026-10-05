import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/withdrawal_request.dart';
import '../providers/wallet_extended_providers.dart';

/// Para çekme — `POST /api/withdrawals`.
class WithdrawalPage extends ConsumerStatefulWidget {
  const WithdrawalPage({super.key});

  @override
  ConsumerState<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends ConsumerState<WithdrawalPage> {
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _ibanCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || amount <= 0) {
      _showError('Çekilecek jeton adedini girin.');
      return;
    }
    final name = _nameCtrl.text.trim();
    final bank = _bankCtrl.text.trim();
    final iban = _ibanCtrl.text.trim().replaceAll(' ', '');
    if (name.isEmpty || bank.isEmpty || iban.length < 15) {
      _showError('Ad soyad, banka ve IBAN zorunludur.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(walletRemoteExtendedProvider).requestWithdrawal(
            amount: amount,
            method: 'bank_transfer',
            details: {
              'fullName': name,
              'bankName': bank,
              'iban': iban,
            },
          );
      ref.invalidate(withdrawalHistoryProvider);
      ref.read(walletBalancesProvider.notifier).refresh(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çekim talebiniz alındı.')),
      );
      context.pop();
    } catch (e) {
      _showError(ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(withdrawalHistoryProvider);
    final wallet = ref.watch(walletBalancesProvider).valueOrNull;
    final membershipInfo = resolveProfileMembership(
      rawMembership: wallet?.membership,
      daysRemaining: wallet?.membershipDaysRemaining,
    );
    final pageSubtitle =
        buildMembershipWithdrawalPageSubtitle(info: membershipInfo);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: buildMembershipWalletCenterWithdrawalTitle(),
          subtitle: pageSubtitle,
          onRefresh: () async {
            ref.invalidate(withdrawalHistoryProvider);
            ref.invalidate(platformCommissionRatesProvider);
          },
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _WithdrawalQuoteCard(jeton: int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0),
              const SizedBox(height: 16),
              _field('Ad Soyad', _nameCtrl, TextInputType.name),
              const SizedBox(height: 10),
              _field('Banka', _bankCtrl, TextInputType.text),
              const SizedBox(height: 10),
              _field('IBAN', _ibanCtrl, TextInputType.text),
              const SizedBox(height: 10),
              _field('Çekilecek Jeton', _amountCtrl, TextInputType.number,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeColors.coinGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Talep Oluştur',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Geçmiş Talepler',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),
              history.when(
                loading: () => const Center(child: DiscoverAccentLoader()),
                error: (e, _) => Text(ApiException.userMessage(e)),
                data: (items) => items.isEmpty
                    ? Text(
                        'Henüz çekim talebi yok.',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      )
                    : Column(
                        children: [
                          for (final w in items)
                            _WithdrawalTile(request: w),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    TextInputType type, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({required this.request});

  final WithdrawalRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.amount.toStringAsFixed(0)} Jeton',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (request.createdAt != null)
                  Text(
                    request.createdAt!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            request.statusLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppThemeColors.coinGold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kesinti ve net tutar — tamamı sunucudan (`GET /api/withdrawals/quote`).
class _WithdrawalQuoteCard extends ConsumerWidget {
  const _WithdrawalQuoteCard({required this.jeton});

  final int jeton;

  static String _tl(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} ₺';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(withdrawalQuoteProvider(jeton));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: quote.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: DiscoverAccentLoader()),
        ),
        error: (e, _) => Text(ApiException.userMessage(e)),
        data: (q) {
          Widget row(String label, String value, {bool strong = false}) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: strong ? 14 : 13,
                        fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: strong ? 16 : 14,
                      color: strong ? AppThemeColors.coinGold : null,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bakiye: ${q.jetonBalance} jeton · Minimum çekim: ${q.minWithdrawal} jeton',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 6),
              row(q.grossLabel, _tl(q.grossTL)),
              row(q.taxLabel, _tl(q.taxAmount)),
              row(q.netLabel, _tl(q.netAmountTL), strong: true),
            ],
          );
        },
      ),
    );
  }
}
