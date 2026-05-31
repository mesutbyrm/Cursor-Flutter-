import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../pages/cfc_purchase_page.dart';
import '../providers/profile_providers.dart';

enum CfcPaymentMethod { whatsapp, papara, bank_transfer }

/// CFC yükleme — canlifal.com `POST /api/payment/requests`.
class CfcNativeCheckout extends ConsumerStatefulWidget {
  const CfcNativeCheckout({
    super.key,
    required this.config,
    required this.onSubmitted,
  });

  final PaymentConfigEntity config;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<CfcNativeCheckout> createState() => _CfcNativeCheckoutState();
}

class _CfcNativeCheckoutState extends ConsumerState<CfcNativeCheckout> {
  final _amountCtrl = TextEditingController(text: '100');
  final _senderCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CfcPaymentMethod _method = CfcPaymentMethod.whatsapp;
  var _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _senderCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final min = cfg.minCfcAmount;
    final rate = cfg.cfcRate > 0 ? cfg.cfcRate : CurrencyUsageInfo.cfcTlPerCoin;
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final tl = CurrencyUsageInfo.tlForCfc(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${CurrencyUsageInfo.cfcPriceHint} · 1 CFC = ${rate.toStringAsFixed(2)} TL · min $min CFC',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.muted.withValues(alpha: 0.95),
          ),
        ),
        if (amount > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Ödenecek tutar: ${tl.toStringAsFixed(tl == tl.roundToDouble() ? 0 : 2)} TL',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.diamondBlue,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [100, 200, 500].map((cfc) {
            return ActionChip(
              label: Text('$cfc CFC (${CurrencyUsageInfo.tlForCfc(cfc).toStringAsFixed(0)} TL)'),
              onPressed: () {
                setState(() => _amountCtrl.text = '$cfc');
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'CFC (CanlıFal Coin) miktarı',
            hintText: 'Örn. 100',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _senderCtrl,
          decoration: InputDecoration(
            labelText: 'Gönderen (ad / telefon)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Ödeme yöntemi', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          subtitle: cfg.whatsappNumber.isEmpty ? 'Henüz ayarlanmadı' : cfg.whatsappNumber,
          selected: _method == CfcPaymentMethod.whatsapp,
          onTap: () => setState(() => _method = CfcPaymentMethod.whatsapp),
        ),
        _MethodTile(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Papara',
          subtitle: cfg.paparaAddress,
          selected: _method == CfcPaymentMethod.papara,
          onTap: () => setState(() => _method = CfcPaymentMethod.papara),
        ),
        _MethodTile(
          icon: Icons.account_balance_rounded,
          label: 'Havale / EFT',
          subtitle: cfg.bankIban,
          selected: _method == CfcPaymentMethod.bank_transfer,
          onTap: () => setState(() => _method = CfcPaymentMethod.bank_transfer),
        ),
        const SizedBox(height: 12),
        GlowPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_detailTitle(), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(
                _detailValue(cfg),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCyan,
                ),
              ),
              if (_method == CfcPaymentMethod.bank_transfer) ...[
                if (cfg.bankName != null && cfg.bankName!.isNotEmpty)
                  Text(cfg.bankName!, style: const TextStyle(fontSize: 12)),
                if (cfg.bankAccountHolder.isNotEmpty)
                  Text(cfg.bankAccountHolder, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Not (isteğe bağlı)',
            hintText: 'Papara ile gönderdim',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copy(cfg),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Kopyala'),
              ),
            ),
            if (_method == CfcPaymentMethod.whatsapp) ...[
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: cfg.whatsappNumber.isEmpty ? null : () => _openWa(cfg),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(cfg),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.diamondBlue,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _method == CfcPaymentMethod.whatsapp
                      ? 'Ödemeyi yaptım — talep gönder'
                      : 'CFC yükleme talebi gönder',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ],
    );
  }

  String _detailTitle() => switch (_method) {
        CfcPaymentMethod.whatsapp => 'WhatsApp numarası',
        CfcPaymentMethod.papara => 'Papara adresi',
        CfcPaymentMethod.bank_transfer => 'IBAN',
      };

  String _detailValue(PaymentConfigEntity cfg) => switch (_method) {
        CfcPaymentMethod.whatsapp => cfg.whatsappNumber,
        CfcPaymentMethod.papara => cfg.paparaAddress,
        CfcPaymentMethod.bank_transfer => cfg.bankIban,
      };

  Future<void> _copy(PaymentConfigEntity cfg) async {
    await Clipboard.setData(ClipboardData(text: _detailValue(cfg)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panoya kopyalandı')),
      );
    }
  }

  Future<void> _openWa(PaymentConfigEntity cfg) async {
    final amount = _amountCtrl.text.trim();
    final msg = Uri.encodeComponent(
      'Merhaba, $amount CFC yüklemek istiyorum.',
    );
    final phone = cfg.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit(PaymentConfigEntity cfg) async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount < cfg.minCfcAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En az ${cfg.minCfcAmount} CFC girebilirsiniz')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).submitPaymentRequest({
        'requestType': 'cfc',
        'type': 'cfc',
        'amount': amount,
        'method': _method.name,
        'senderInfo': _senderCtrl.text.trim().isEmpty ? null : _senderCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty
            ? 'CFC yükleme · ${_method.name}'
            : _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(cfcPaymentRequestsProvider);
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
      ref.invalidate(notificationsListProvider);
      widget.onSubmitted();
      if (_method == CfcPaymentMethod.whatsapp) {
        await _openWa(cfg);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Talep gönderildi. Yönetim paneline bildirim düştü; onay sonrası CFC yansır.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.diamondBlue.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppColors.diamondBlue : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.diamondBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
