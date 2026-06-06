import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../providers/profile_providers.dart';

enum PaymentMethodKind { whatsapp, papara, bank_transfer }

/// Site tarzı ödeme — WhatsApp, Papara, Havale/EFT (web’e gitmeden).
class JetonNativeCheckout extends ConsumerStatefulWidget {
  const JetonNativeCheckout({
    super.key,
    required this.package,
    required this.priceText,
    required this.onSubmitted,
  });

  final JetonPackageEntity package;
  final String priceText;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<JetonNativeCheckout> createState() =>
      _JetonNativeCheckoutState();
}

class _JetonNativeCheckoutState extends ConsumerState<JetonNativeCheckout> {
  PaymentMethodKind _method = PaymentMethodKind.whatsapp;
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(paymentConfigProvider);

    return config.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(ApiException.userMessage(e)),
      data: (cfg) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.package.title} · ${widget.priceText}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Ödeme yöntemi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          _MethodTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            subtitle: 'Mesaj ile ödeme bildirimi',
            selected: _method == PaymentMethodKind.whatsapp,
            onTap: () => setState(() => _method = PaymentMethodKind.whatsapp),
          ),
          _MethodTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Papara',
            subtitle: cfg.paparaAddress,
            selected: _method == PaymentMethodKind.papara,
            onTap: () => setState(() => _method = PaymentMethodKind.papara),
          ),
          _MethodTile(
            icon: Icons.account_balance_rounded,
            label: 'Havale / EFT',
            subtitle: cfg.bankIban,
            selected: _method == PaymentMethodKind.bank_transfer,
            onTap: () => setState(() => _method = PaymentMethodKind.bank_transfer),
          ),
          SizedBox(height: 16),
          GlowPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detailTitle(cfg),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                SelectableText(
                  _detailValue(cfg),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppThemeColors.accentCyan,
                  ),
                ),
                if (_method == PaymentMethodKind.bank_transfer) ...[
                  if (cfg.bankName != null) ...[
                    SizedBox(height: 6),
                    Text(cfg.bankName!, style: TextStyle(fontSize: 12)),
                  ],
                  if (cfg.bankAccountHolder.isNotEmpty)
                    Text(
                      cfg.bankAccountHolder,
                      style: TextStyle(fontSize: 12),
                    ),
                ],
                SizedBox(height: 10),
                Text(
                  'Ödemeyi yaptıktan sonra «Talep gönder» ile admin ve site bildirim paneline düşer.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyDetail(cfg),
                  icon: Icon(Icons.copy_rounded, size: 18),
                  label: Text('Kopyala'),
                ),
              ),
              if (_method == PaymentMethodKind.whatsapp) ...[
                SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openWhatsApp(cfg),
                    icon: Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('WhatsApp'),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : () => _submit(cfg),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppThemeColors.accentPink,
            ),
            child: _submitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Ödeme bilgisi / WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  String _detailTitle(PaymentConfigEntity cfg) {
    return switch (_method) {
      PaymentMethodKind.whatsapp => 'WhatsApp numarası',
      PaymentMethodKind.papara => 'Papara adresi',
      PaymentMethodKind.bank_transfer => 'IBAN',
    };
  }

  String _detailValue(PaymentConfigEntity cfg) {
    return switch (_method) {
      PaymentMethodKind.whatsapp => cfg.whatsappNumber,
      PaymentMethodKind.papara => cfg.paparaAddress,
      PaymentMethodKind.bank_transfer => cfg.bankIban,
    };
  }

  Future<void> _copyDetail(PaymentConfigEntity cfg) async {
    await Clipboard.setData(ClipboardData(text: _detailValue(cfg)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panoya kopyalandı')),
      );
    }
  }

  Future<void> _openWhatsApp(PaymentConfigEntity cfg) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final msg = Uri.encodeComponent(
      'Merhaba, ${widget.package.title} (${widget.package.coins} jeton) '
      'satın almak istiyorum. Kullanıcı: ${user?.display ?? "misafir"}',
    );
    final phone = cfg.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit(PaymentConfigEntity cfg) async {
    if (_method == PaymentMethodKind.whatsapp) {
      await _openWhatsApp(cfg);
    } else {
      await _copyDetail(cfg);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Jeton paketi için ödemeyi yaptıktan sonra destek onayı gerekir. '
          'CFC yüklemek için Profil → CFC Yükle.',
        ),
      ),
    );
    widget.onSubmitted();
    Navigator.of(context).pop();
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
            ? AppThemeColors.accentPurple.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppThemeColors.accentPink : context.colors.onSurfaceMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: AppThemeColors.accentPink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
