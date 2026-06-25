import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../data/jeton_payment_request.dart';
import '../../data/services/payment_receipt_upload_service.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

/// Sabit kur: 1 Jeton = ₺0,50
const double kJetonPurchaseTlRate = kDefaultJetonTlRate;

const List<double> kJetonQuickTlPresets = [250, 500, 1000, 2500];

const String kJetonPaymentTransferWarning =
    'DİKKAT !!! ÖDEME YAPARKEN DİKKAT EDİNİZ... '
    'Bireysel ödemeyi seçip, Açıklama kısmına birşey yazmayın... '
    'açıklamada jeton, borç veya herhangi birşey yazılırsa kesintisi yapılıp '
    'ücret iadesi aynı şekilde yapılacaktır.';

enum JetonPayMethod { papara, bank, whatsapp }

/// Premium 2026 jeton satın alma — çift yönlü TL/jeton, hazır tutarlar, ödeme yöntemleri.
class JetonPremiumPurchaseView extends ConsumerStatefulWidget {
  const JetonPremiumPurchaseView({super.key});

  @override
  ConsumerState<JetonPremiumPurchaseView> createState() =>
      _JetonPremiumPurchaseViewState();
}

class _JetonPremiumPurchaseViewState
    extends ConsumerState<JetonPremiumPurchaseView> {
  final _tlCtrl = TextEditingController();
  final _jetonCtrl = TextEditingController();
  var _syncing = false;
  var _submitting = false;
  double? _selectedPresetTl;
  JetonPayMethod? _method;
  String? _receiptPath;

  @override
  void dispose() {
    _tlCtrl.dispose();
    _jetonCtrl.dispose();
    super.dispose();
  }

  void _syncFromTl(String raw) {
    if (_syncing) return;
    _syncing = true;
    final tl = double.tryParse(raw.replaceAll(',', '.'));
    if (tl == null || tl <= 0) {
      _jetonCtrl.text = '';
    } else {
      final jeton = (tl / kJetonPurchaseTlRate).round();
      _jetonCtrl.text = jeton > 0 ? '$jeton' : '';
    }
    _syncing = false;
    setState(() => _selectedPresetTl = null);
  }

  void _syncFromJeton(String raw) {
    if (_syncing) return;
    _syncing = true;
    final jeton = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (jeton == null || jeton <= 0) {
      _tlCtrl.text = '';
    } else {
      final tl = jeton * kJetonPurchaseTlRate;
      _tlCtrl.text = _formatTlInput(tl);
    }
    _syncing = false;
    setState(() => _selectedPresetTl = null);
  }

  void _applyPreset(double tl) {
    final jeton = (tl / kJetonPurchaseTlRate).round();
    setState(() {
      _selectedPresetTl = tl;
      _tlCtrl.text = _formatTlInput(tl);
      _jetonCtrl.text = '$jeton';
    });
  }

  String _formatTlInput(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _formatTryDisplay(double v) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return fmt.format(v);
  }

  ({int jeton, double tl, bool valid, String? error}) _parseAmounts() {
    final jetonRaw = int.tryParse(_jetonCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), ''));
    final tlRaw = double.tryParse(_tlCtrl.text.trim().replaceAll(',', '.'));
    final jetonFromTl = tlRaw != null && tlRaw > 0
        ? (tlRaw / kJetonPurchaseTlRate).round()
        : null;

    final jeton = jetonRaw ?? jetonFromTl;
    if (jeton == null || jeton < 1) {
      return (jeton: 0, tl: 0, valid: false, error: 'En az 1 jeton girin');
    }

    final tl = tlRaw ?? (jeton * kJetonPurchaseTlRate);
    if (tl < kJetonPurchaseTlRate) {
      return (
        jeton: jeton,
        tl: tl,
        valid: false,
        error: 'Geçerli bir TL tutarı girin (min ₺0,50)',
      );
    }

    return (jeton: jeton, tl: tl, valid: true, error: null);
  }

  PaymentConfigEntity _config() {
    final remote = ref.read(paymentConfigProvider).valueOrNull;
    return remote != null ? PaymentDefaults.merge(remote) : PaymentDefaults.config;
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 82);
    if (file == null) return;
    setState(() => _receiptPath = file.path);
  }

  Future<void> _pickReceiptFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    setState(() => _receiptPath = path);
  }

  Future<void> _openWhatsApp({
    required int jeton,
    required double tl,
    required String username,
    required PaymentConfigEntity cfg,
  }) async {
    final phone = PaymentDefaults.formatWhatsAppPhone(cfg.whatsappNumber);
    final msg = Uri.encodeComponent(
      'Merhaba.\n'
      'Canlifal için jeton satın almak istiyorum.\n\n'
      'Kullanıcı:\n$username\n\n'
      'Jeton:\n$jeton\n\n'
      'Tutar:\n${_formatTryDisplay(tl)}',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp açılamadı')),
      );
    }
  }

  Future<void> _submit() async {
    final amounts = _parseAmounts();
    if (!amounts.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(amounts.error ?? 'Geçersiz tutar')),
      );
      return;
    }
    if (_method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme yöntemi seçin')),
      );
      return;
    }

    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum açmanız gerekiyor')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      String? receiptUrl;
      if (_receiptPath != null && _receiptPath!.isNotEmpty) {
        try {
          receiptUrl = await ref
              .read(paymentReceiptUploadServiceProvider)
              .uploadFile(File(_receiptPath!))
              .timeout(const Duration(seconds: 12));
        } catch (_) {
          receiptUrl = null;
        }
      }

      final methodApi = switch (_method!) {
        JetonPayMethod.papara => 'papara',
        JetonPayMethod.bank => 'bank_transfer',
        JetonPayMethod.whatsapp => 'whatsapp',
      };
      final username = me.display;
      final remotePackages =
          await ref.read(jetonPackagesProvider.future).catchError((_) => <JetonPackageEntity>[]);
      final package = resolveJetonPackageForPurchase(
        coins: amounts.jeton,
        priceTry: amounts.tl,
        remote: remotePackages,
      );
      final body = buildJetonPaymentRequest(
        package: package,
        method: methodApi,
        notes: 'Jeton yükleme · $methodApi · $username',
        senderLabel: username,
        receiptReference: receiptUrl,
      );

      await ref
          .read(walletRepositoryProvider)
          .submitPaymentRequest(body)
          .timeout(const Duration(seconds: 35));
      ref.refreshWalletCache(force: true);
      ref.invalidate(paymentRequestsNotifierProvider);
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(notificationsListNotifierProvider);

      if (!mounted) return;

      if (_method == JetonPayMethod.whatsapp) {
        await _openWhatsApp(
          jeton: amounts.jeton,
          tl: amounts.tl,
          username: username,
          cfg: _config(),
        );
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: AppThemeColors.accentCyan, size: 36),
          title: const Text('Ödeme talebi oluşturuldu'),
          content: const Text(
            'Talebiniz admin ekibine iletildi. Onay sonrası jetonlar hesabınıza yansır.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletBalancesProvider);
    final config = ref.watch(paymentConfigProvider).valueOrNull;
    final cfg = config != null ? PaymentDefaults.merge(config) : PaymentDefaults.config;
    final me = ref.watch(authControllerProvider).valueOrNull;
    final username = me?.display ?? me?.username ?? 'Kullanıcı';
    final amounts = _parseAmounts();

    return ResponsiveConstrained(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            wallet.when(
              data: (b) => _BalanceCard(jeton: b.jeton),
              loading: () => const _BalanceCard(jeton: null),
              error: (_, _) => const _BalanceCard(jeton: null),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Tutar Belirle'),
            const SizedBox(height: 4),
            Text(
              '1 Jeton = ₺${kJetonPurchaseTlRate.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountField(
                    label: 'TL Tutarı',
                    controller: _tlCtrl,
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _syncFromTl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AmountField(
                    label: 'Jeton Miktarı',
                    controller: _jetonCtrl,
                    icon: Icons.monetization_on_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: _syncFromJeton,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Hazır Seçimler'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 520 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: cols == 4 ? 1.55 : 1.8,
                  children: [
                    for (final tl in kJetonQuickTlPresets)
                      _PresetCard(
                        tl: tl,
                        jeton: (tl / kJetonPurchaseTlRate).round(),
                        selected: _selectedPresetTl == tl,
                        onTap: () => _applyPreset(tl),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Ödeme Yöntemi'),
            const SizedBox(height: 10),
            _MethodTile(
              title: 'Papara',
              subtitle: 'Anında transfer',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF7C3AED),
              selected: _method == JetonPayMethod.papara,
              onTap: () => setState(() => _method = JetonPayMethod.papara),
            ),
            const SizedBox(height: 8),
            _MethodTile(
              title: 'Banka Havalesi / EFT',
              subtitle: 'IBAN ile transfer',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF2563EB),
              selected: _method == JetonPayMethod.bank,
              onTap: () => setState(() => _method = JetonPayMethod.bank),
            ),
            const SizedBox(height: 8),
            _MethodTile(
              title: 'WhatsApp Destek',
              subtitle: 'Tek tıkla destek hattı',
              icon: Icons.chat_rounded,
              color: const Color(0xFF25D366),
              selected: _method == JetonPayMethod.whatsapp,
              onTap: () async {
                setState(() => _method = JetonPayMethod.whatsapp);
                if (amounts.valid) {
                  await _openWhatsApp(
                    jeton: amounts.jeton,
                    tl: amounts.tl,
                    username: username,
                    cfg: cfg,
                  );
                }
              },
            ),
            if (_method == JetonPayMethod.papara) ...[
              const SizedBox(height: 14),
              _DetailCard(
                children: [
                  _CopyRow(label: 'Papara No', value: cfg.paparaAddress),
                  if (cfg.bankAccountHolder.isNotEmpty) ...[
                    const Divider(height: 20, color: Colors.white12),
                    _InfoRow(label: 'Alıcı', value: cfg.bankAccountHolder),
                  ],
                ],
              ),
              const _PaymentWarningCard(),
              _ReceiptSection(
                path: _receiptPath,
                onGallery: () => _pickReceipt(ImageSource.gallery),
                onCamera: () => _pickReceipt(ImageSource.camera),
                onFile: _pickReceiptFile,
                onClear: () => setState(() => _receiptPath = null),
              ),
            ],
            if (_method == JetonPayMethod.bank) ...[
              const SizedBox(height: 14),
              _DetailCard(
                children: [
                  _InfoRow(label: 'Banka', value: cfg.bankName ?? '—'),
                  const Divider(height: 16, color: Colors.white12),
                  _InfoRow(label: 'Alıcı', value: cfg.bankAccountHolder),
                  const Divider(height: 16, color: Colors.white12),
                  _CopyRow(label: 'IBAN', value: cfg.bankIban),
                ],
              ),
              const _PaymentWarningCard(),
              _ReceiptSection(
                path: _receiptPath,
                onGallery: () => _pickReceipt(ImageSource.gallery),
                onCamera: () => _pickReceipt(ImageSource.camera),
                onFile: _pickReceiptFile,
                onClear: () => setState(() => _receiptPath = null),
              ),
            ],
            if (_method == JetonPayMethod.whatsapp) ...[
              const SizedBox(height: 14),
              _DetailCard(
                children: [
                  Text(
                    'WhatsApp ile ödeme yaptıktan sonra «Satın Al» ile talebi iletin.',
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting || !amounts.valid || _method == null
                  ? null
                  : () => unawaited(_submit()),
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_bag_rounded),
              label: Text(
                _submitting ? 'Gönderiliyor…' : 'Satın Al',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PaymentWarningCard extends StatelessWidget {
  const _PaymentWarningCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SelectionContainer.disabled(
        child: ProGlassCard(
          blur: 12,
          animateIn: false,
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  kJetonPaymentTransferWarning,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({this.jeton});

  final int? jeton;

  @override
  Widget build(BuildContext context) {
    return ProGlassCard(
      blur: 16,
      animateIn: false,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.coinGold.withValues(alpha: 0.25),
                  AppThemeColors.accentPurple.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: AppThemeColors.coinGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Jeton',
                  style: TextStyle(
                    color: context.colors.onSurfaceMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jeton == null ? '…' : '$jeton',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppThemeColors.coinGold,
                    letterSpacing: -0.5,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.keyboardType,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProGlassCard(
      blur: 12,
      animateIn: false,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: [
          if (keyboardType == TextInputType.number)
            FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.tl,
    required this.jeton,
    required this.selected,
    required this.onTap,
  });

  final double tl;
  final int jeton;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return ProGlassCard(
      onTap: onTap,
      blur: 12,
      animateIn: false,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppThemeColors.coinGold, width: 2)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fmt.format(tl),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppThemeColors.coinGold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$jeton jeton',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProGlassCard(
      onTap: onTap,
      blur: 12,
      animateIn: false,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ProGlassCard(
      blur: 12,
      animateIn: false,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.colors.onSurfaceMuted)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.colors.onSurfaceMuted)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
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
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({
    required this.path,
    required this.onGallery,
    required this.onCamera,
    required this.onFile,
    required this.onClear,
  });

  final String? path;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onFile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ProGlassCard(
        blur: 12,
        animateIn: false,
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dekont Yükle', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri'),
                ),
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Kamera'),
                ),
                OutlinedButton.icon(
                  onPressed: onFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Dosya'),
                ),
                if (path != null)
                  TextButton(onPressed: onClear, child: const Text('Kaldır')),
              ],
            ),
            if (path != null && !path!.toLowerCase().endsWith('.pdf')) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: FileImage(File(path!)),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
