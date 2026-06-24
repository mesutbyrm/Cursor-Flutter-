import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../data/jeton_payment_request.dart';
import '../../data/jeton_purchase_prefs.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

enum _NotifyMethod { whatsapp, other }

/// Mockup: «Ödeme Bildir» alt sayfası — WhatsApp / Diğer, tutar, referans, başarı ekranı.
Future<void> openJetonPaymentNotifySheet(
  BuildContext context,
  WidgetRef ref, {
  JetonPackageEntity? package,
  double? priceTry,
  VoidCallback? onDone,
}) {
  final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _JetonPaymentNotifySheet(
            initialPackage: package,
            initialPriceTry: priceTry,
            onDone: onDone,
          ),
        ),
      );
    },
  );
}

class _JetonPaymentNotifySheet extends ConsumerStatefulWidget {
  const _JetonPaymentNotifySheet({
    this.initialPackage,
    this.initialPriceTry,
    this.onDone,
  });

  final JetonPackageEntity? initialPackage;
  final double? initialPriceTry;
  final VoidCallback? onDone;

  @override
  ConsumerState<_JetonPaymentNotifySheet> createState() =>
      _JetonPaymentNotifySheetState();
}

class _JetonPaymentNotifySheetState
    extends ConsumerState<_JetonPaymentNotifySheet> {
  final _amountCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _senderCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _prefs = JetonPurchasePrefs();

  _NotifyMethod _method = _NotifyMethod.whatsapp;
  var _submitting = false;
  var _success = false;
  JetonPackageEntity? _package;

  @override
  void initState() {
    super.initState();
    _package = widget.initialPackage;
    final price = widget.initialPriceTry ?? widget.initialPackage?.priceTry;
    if (price != null && price > 0) {
      _amountCtrl.text = price == price.roundToDouble()
          ? price.toInt().toString()
          : price.toStringAsFixed(2);
    }
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me != null) {
      _senderCtrl.text = me.display.trim().isNotEmpty
          ? me.display.trim()
          : me.username;
    }
    _notesCtrl.text = 'Jeton alma';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receiptCtrl.dispose();
    _senderCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _methodApi => _method == _NotifyMethod.whatsapp
      ? 'whatsapp'
      : 'bank_transfer';

  JetonPackageEntity _buildPackage(double priceTry) {
    final existing = _package;
    if (existing != null) {
      return JetonPackageEntity(
        id: existing.id,
        title: existing.title,
        coins: existing.coins,
        priceTry: priceTry,
        priceLabel: existing.priceLabel,
        badge: existing.badge,
      );
    }
    final rate = kDefaultJetonTlRate;
    final coins = (priceTry / rate).round().clamp(1, 999999);
    return JetonPackageEntity(
      id: 'notify_$coins',
      title: '$coins Jeton',
      coins: coins,
      priceTry: priceTry,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    final priceTry = double.tryParse(raw);
    if (priceTry == null || priceTry <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar girin')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final pkg = _buildPackage(priceTry);
      final notes = _notesCtrl.text.trim();
      final body = buildJetonPaymentRequest(
        package: pkg,
        method: _methodApi,
        notes: notes.isEmpty ? 'Jeton yükleme · $_methodApi' : notes,
        senderLabel: _senderCtrl.text.trim().isEmpty
            ? null
            : _senderCtrl.text.trim(),
        receiptReference: _receiptCtrl.text.trim().isEmpty
            ? null
            : _receiptCtrl.text.trim(),
      );
      await ref.read(walletRepositoryProvider).submitPaymentRequest(body).timeout(
            const Duration(seconds: 35),
            onTimeout: () => throw const ApiException(
              'Ödeme bildirimi zaman aşımına uğradı. Tekrar deneyin.',
            ),
          );
      await _prefs.saveLastPackageId(pkg.id);
      await _prefs.saveLastPaymentMethod(_methodApi);
      ref.refreshWalletCache(force: true);
      ref.invalidate(paymentRequestsNotifierProvider);
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(notificationsListNotifierProvider);
      if (!mounted) return;
      setState(() => _success = true);
      widget.onDone?.call();
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

  void _applyPreset(JetonPackageEntity preset) {
    setState(() {
      _package = preset;
      final price = preset.priceTry;
      if (price != null && price > 0) {
        _amountCtrl.text = price == price.roundToDouble()
            ? price.toInt().toString()
            : price.toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF12081F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _success ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF22C55E),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bildirim Gönderildi!',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            'Ödemeniz en kısa sürede kontrol edilip onaylanacaktır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.accentPurple,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      shrinkWrap: true,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        _SheetHeader(onClose: () => Navigator.of(context).pop()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ödeme yöntemi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MethodChip(
                      label: 'WhatsApp',
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      selected: _method == _NotifyMethod.whatsapp,
                      onTap: () =>
                          setState(() => _method = _NotifyMethod.whatsapp),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MethodChip(
                      label: 'Diğer',
                      icon: Icons.credit_card_rounded,
                      iconColor: AppThemeColors.accentPurple,
                      selected: _method == _NotifyMethod.other,
                      onTap: () =>
                          setState(() => _method = _NotifyMethod.other),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in kFallbackJetonPackages)
                    ActionChip(
                      label: Text('${p.coins} jeton'),
                      backgroundColor: _package?.coins == p.coins
                          ? AppThemeColors.accentPurple.withValues(alpha: 0.35)
                          : const Color(0xFF1A1030),
                      side: BorderSide(
                        color: _package?.coins == p.coins
                            ? AppThemeColors.accentPink
                            : AppThemeColors.accentPurple.withValues(alpha: 0.35),
                      ),
                      onPressed: () => _applyPreset(p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _LabeledField(
                label: 'Tutar (₺) *',
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'İşlem No / Referans (opsiyonel)',
                child: TextField(
                  controller: _receiptCtrl,
                  decoration: _fieldDecoration(hint: '123456688'),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Gönderen İsmi (opsiyonel)',
                child: TextField(
                  controller: _senderCtrl,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Not (opsiyonel)',
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.45),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ödemenizi yaptıktan sonra bu formu doldurarak bildirim gönderin. '
                        'Ekibimiz ödemenizi kontrol edip jetonlarınızı en kısa sürede yükleyecektir.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: context.colors.onSurfaceMuted
                              .withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitting ? null : () => unawaited(_submit()),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFE2C55),
                          Color(0xFFB832FF),
                          Color(0xFF7C3AED),
                        ],
                      ),
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ödeme Bildir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF1A1030),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9D6BFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppThemeColors.accentPurple.withValues(alpha: 0.55),
            const Color(0xFF4C1D95).withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ödeme Bildir',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Jeton yükleme ödemesi bildirin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1A1030),
            border: Border.all(
              color: selected
                  ? AppThemeColors.accentPink
                  : AppThemeColors.accentPurple.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.colors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
