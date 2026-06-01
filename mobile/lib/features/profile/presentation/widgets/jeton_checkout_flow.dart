import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/jeton_payment_request.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

/// Jeton satın alma — mockup: ödeme yöntemi → WhatsApp / Papara / Havale.
void openJetonCheckoutFlow(
  BuildContext context,
  WidgetRef ref, {
  required JetonPackageEntity package,
  required String priceText,
  required VoidCallback onDone,
  String? paymentNotes,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _JetonPaymentMethodPage(
        package: package,
        priceText: priceText,
        paymentNotes: paymentNotes,
        onDone: () {
          onDone();
          Navigator.of(ctx).pop();
        },
      ),
    ),
  );
}

class _JetonPaymentMethodPage extends ConsumerWidget {
  const _JetonPaymentMethodPage({
    required this.package,
    required this.priceText,
    required this.onDone,
    this.paymentNotes,
  });

  final JetonPackageEntity package;
  final String priceText;
  final VoidCallback onDone;
  final String? paymentNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    final userLabel = me?.display ?? me?.username ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0216),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFFFFD54F),
              title: 'Ödeme Yöntemi',
              subtitle: 'Güvenli ödeme seçenekleri',
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PackageSummaryCard(
                title: package.title,
                priceText: priceText,
                userLabel: userLabel,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: _SectionDivider(label: 'Ödeme Yöntemleri'),
            ),
            _MethodCard(
              color: const Color(0xFF25D366),
              icon: Icons.chat_rounded,
              title: 'WhatsApp',
              badge: 'Önerilen',
              subtitle: 'Hızlı ve kolay ödeme',
              onTap: () => _openDetail(context, ref, _JetonPayMethod.whatsapp),
            ),
            _MethodCard(
              color: const Color(0xFF312E81),
              icon: Icons.account_balance_wallet_rounded,
              title: 'Papara',
              subtitle: 'Papara ile ödeme',
              onTap: () => _openDetail(context, ref, _JetonPayMethod.papara),
            ),
            _MethodCard(
              color: const Color(0xFF1E3A5F),
              icon: Icons.account_balance_rounded,
              title: 'Havale / IBAN',
              subtitle: 'Banka havalesi ile ödeme',
              onTap: () => _openDetail(context, ref, _JetonPayMethod.bank),
            ),
            const Spacer(),
            const _TrustFooter(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, _JetonPayMethod method) {
    final remote = ref.read(paymentConfigProvider).valueOrNull;
    final config = remote != null
        ? PaymentDefaults.merge(remote)
        : PaymentDefaults.config;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _JetonPaymentDetailPage(
          method: method,
          package: package,
          priceText: priceText,
          config: config,
          paymentNotes: paymentNotes,
          onDone: onDone,
        ),
      ),
    );
  }
}

enum _JetonPayMethod { whatsapp, papara, bank }

class _JetonPaymentDetailPage extends ConsumerStatefulWidget {
  const _JetonPaymentDetailPage({
    required this.method,
    required this.package,
    required this.priceText,
    required this.config,
    required this.onDone,
    this.paymentNotes,
  });

  final _JetonPayMethod method;
  final JetonPackageEntity package;
  final String priceText;
  final PaymentConfigEntity config;
  final VoidCallback onDone;
  final String? paymentNotes;

  @override
  ConsumerState<_JetonPaymentDetailPage> createState() =>
      _JetonPaymentDetailPageState();
}

class _JetonPaymentDetailPageState extends ConsumerState<_JetonPaymentDetailPage> {
  var _submitting = false;

  String get _userLabel {
    final me = ref.read(authControllerProvider).valueOrNull;
    return me?.display ?? me?.username ?? 'Kullanıcı';
  }

  String get _methodApi => switch (widget.method) {
        _JetonPayMethod.whatsapp => 'whatsapp',
        _JetonPayMethod.papara => 'papara',
        _JetonPayMethod.bank => 'bank_transfer',
      };

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final title = switch (widget.method) {
      _JetonPayMethod.whatsapp => 'WhatsApp ile Ödeme',
      _JetonPayMethod.papara => 'Papara ile Ödeme',
      _JetonPayMethod.bank => 'Banka Transferi',
    };
    final headerIcon = switch (widget.method) {
      _JetonPayMethod.whatsapp => Icons.chat_rounded,
      _JetonPayMethod.papara => Icons.account_balance_wallet_rounded,
      _JetonPayMethod.bank => Icons.account_balance_rounded,
    };
    final headerColor = switch (widget.method) {
      _JetonPayMethod.whatsapp => const Color(0xFF25D366),
      _JetonPayMethod.papara => AppColors.accentPurple,
      _JetonPayMethod.bank => const Color(0xFF60A5FA),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0D0216),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: headerIcon,
              iconColor: headerColor,
              title: title,
              onClose: () => Navigator.pop(context),
            ),
            if (widget.method == _JetonPayMethod.whatsapp) ...[
              _InfoCard(
                child: Column(
                  children: [
                    _RowLabel('Jeton Miktarı:', '${widget.package.coins}',
                        valueColor: const Color(0xFFFFD54F)),
                    const Divider(height: 20, color: Colors.white12),
                    _RowLabel('Toplam:', widget.priceText,
                        valueColor: const Color(0xFFFFD54F)),
                  ],
                ),
              ),
              _UserInfoCard(
                name: _userLabel,
                email: ref.watch(authControllerProvider).valueOrNull?.username ?? '—',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Butona tıklayarak WhatsApp üzerinden sipariş verin. '
                  'Mesaj otomatik hazırlanır ve talep admin paneline düşer.',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ),
            ] else ...[
              _InfoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.package.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD54F),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      widget.priceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.method == _JetonPayMethod.papara)
                _CopyDetailCard(
                  label: 'Papara No:',
                  value: cfg.paparaAddress,
                )
              else
                _BankDetailCard(config: cfg),
              if (widget.method == _JetonPayMethod.papara)
                _InfoCard(
                  child: _RowLabel('Alıcı:', cfg.bankAccountHolder),
                ),
              _UsernameWarning(username: _userLabel),
            ],
            const Spacer(),
            if (widget.method == _JetonPayMethod.whatsapp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _whatsappOrder,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp\'tan Sipariş Ver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: _submitting ? null : _submitAndClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ödemeyi yaptım — talep gönder',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← Geri Dön'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    final body = widget.package.id.startsWith('membership_')
        ? buildMembershipPaymentRequest(
            package: widget.package,
            method: _methodApi,
            notes: widget.paymentNotes,
          )
        : buildJetonPaymentRequest(
            package: widget.package,
            method: _methodApi,
            notes: widget.paymentNotes,
          );
    await ref.read(walletRepositoryProvider).submitPaymentRequest(body);
    ref.invalidate(walletBalancesProvider);
    ref.invalidate(paymentRequestsNotifierProvider);
    ref.invalidate(adminPaymentRequestsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(notificationsListProvider);
  }

  Future<void> _whatsappOrder() async {
    setState(() => _submitting = true);
    try {
      await _submitRequest();
      final phone = widget.config.whatsappNumber.replaceAll(RegExp(r'\D'), '');
      final msg = Uri.encodeComponent(
        'Merhaba, ${widget.package.title} (${widget.package.coins} jeton) '
        'satın almak istiyorum. Kullanıcı: $_userLabel · Açıklama: $_userLabel',
      );
      final uri = Uri.parse('https://wa.me/$phone?text=$msg');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talebiniz alındı')),
        );
        widget.onDone();
        Navigator.of(context).pop(true);
      }
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

  Future<void> _submitAndClose() async {
    setState(() => _submitting = true);
    try {
      await _submitRequest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ödeme bildirimi gönderildi. Onay sonrası jeton bakiyenize yansır; '
              'Bildirimler sekmesinden takip edebilirsiniz.',
            ),
          ),
        );
        widget.onDone();
        Navigator.of(context).pop(true);
      }
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onClose,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _PackageSummaryCard extends StatelessWidget {
  const _PackageSummaryCard({
    required this.title,
    required this.priceText,
    required this.userLabel,
  });

  final String title;
  final String priceText;
  final String userLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
        color: const Color(0xFF1A0B2E),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🪙', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(priceText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.textMuted.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text(userLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.color,
    required this.icon,
    required this.title,
    this.badge,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? badge;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: Colors.white)),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.verified_rounded, color: const Color(0xFF25D366).withValues(alpha: 0.95)),
          const SizedBox(height: 6),
          const Text('Güvenli Ödeme',
              style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w700)),
          Text(
            'Tüm işlemleriniz güvence altında',
            style: TextStyle(fontSize: 12, color: const Color(0xFF25D366).withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accentPurple,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyDetailCard extends StatelessWidget {
  const _CopyDetailCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted)),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopyalandı')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Kopyala'),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ],
      ),
    );
  }
}

class _BankDetailCard extends StatelessWidget {
  const _BankDetailCard({required this.config});
  final PaymentConfigEntity config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          child: Column(
            children: [
              _RowLabel('Banka:', config.bankName ?? '—'),
              const Divider(height: 16, color: Colors.white12),
              _RowLabel('Alıcı:', config.bankAccountHolder),
            ],
          ),
        ),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IBAN:', style: TextStyle(color: AppColors.textMuted)),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: config.bankIban));
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IBAN kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Kopyala'),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  config.bankIban,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsernameWarning extends StatelessWidget {
  const _UsernameWarning({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45)),
        color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD54F), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, height: 1.35),
                children: [
                  const TextSpan(text: 'Açıklama kısmına kullanıcı adınızı yazın: '),
                  TextSpan(
                    text: "'$username'",
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
