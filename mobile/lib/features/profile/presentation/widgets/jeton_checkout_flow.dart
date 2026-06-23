import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/jeton_payment_request.dart';
import '../../data/jeton_purchase_prefs.dart';
import '../../data/services/payment_receipt_upload_service.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
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
              child: Text('İptal', style: TextStyle(color: context.colors.onSurfaceMuted)),
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
  String? _receiptImagePath;
  final _prefs = JetonPurchasePrefs();

  @override
  void initState() {
    super.initState();
    if (widget.method == _JetonPayMethod.whatsapp) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWhatsAppChat());
    }
  }

  String get _userLabel {
    final me = ref.read(authControllerProvider).valueOrNull;
    return me?.display ?? me?.username ?? 'Kullanıcı';
  }

  String get _methodApi => switch (widget.method) {
        _JetonPayMethod.whatsapp => 'whatsapp',
        _JetonPayMethod.papara => 'papara',
        _JetonPayMethod.bank => 'bank_transfer',
      };

  String _whatsappDisplay(String raw) {
    final digits = PaymentDefaults.formatWhatsAppPhone(raw);
    return digits.startsWith('90') ? '+$digits' : raw;
  }

  Future<void> _openWhatsAppChat() async {
    final phone = PaymentDefaults.formatWhatsAppPhone(
      widget.config.whatsappNumber,
    );
    final receiptPart =
        _receiptImagePath != null ? ' · Dekont eklendi' : '';
    final msg = Uri.encodeComponent(
      'Merhaba, ${widget.package.title} (${widget.package.coins} jeton) '
      'satın almak istiyorum.\n'
      'Ödeme türü: WhatsApp\n'
      'Kullanıcı: $_userLabel\n'
      'Tutar: ${widget.priceText}$receiptPart',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WhatsApp açılamadı. Numara: ${_whatsappDisplay(widget.config.whatsappNumber)}',
          ),
        ),
      );
    }
  }

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
      _JetonPayMethod.papara => AppThemeColors.accentPurple,
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
              _CopyDetailCard(
                label: 'WhatsApp:',
                value: _whatsappDisplay(cfg.whatsappNumber),
              ),
              _UserInfoCard(
                name: _userLabel,
                email: ref.watch(authControllerProvider).valueOrNull?.username ?? '—',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ödemeyi yaptıktan sonra «Ödeme Bildir» ile talebi iletin. '
                  'Admin ekibine bildirim gider; onay sonrası jetonlar hesabınıza yansır.',
                  style: TextStyle(
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ),
              _ReceiptPickerSection(
                imagePath: _receiptImagePath,
                onPickGallery: _pickReceiptGallery,
                onPickCamera: _pickReceiptCamera,
                onPickPdf: _pickReceiptPdf,
                onClear: () => setState(() => _receiptImagePath = null),
              ),
            ] else ...[
              _InfoCard(
                child: Column(
                  children: [
                    _RowLabel('Paket:', widget.package.title,
                        valueColor: const Color(0xFFFFD54F)),
                    const Divider(height: 16, color: Colors.white12),
                    _RowLabel('Jeton:', '${widget.package.coins}',
                        valueColor: const Color(0xFFFFD54F)),
                    const Divider(height: 16, color: Colors.white12),
                    _RowLabel('Tutar:', widget.priceText,
                        valueColor: const Color(0xFFFFD54F)),
                  ],
                ),
              ),
              if (widget.method == _JetonPayMethod.papara) ...[
                _CopyDetailCard(
                  label: 'Papara Ad Soyad:',
                  value: cfg.bankAccountHolder.isNotEmpty
                      ? cfg.bankAccountHolder
                      : '—',
                ),
                _CopyDetailCard(
                  label: 'Papara No:',
                  value: cfg.paparaAddress,
                ),
              ] else
                _BankDetailCard(config: cfg),
              _UsernameWarning(username: _userLabel),
              _ReceiptPickerSection(
                imagePath: _receiptImagePath,
                onPickGallery: _pickReceiptGallery,
                onPickCamera: _pickReceiptCamera,
                onPickPdf: _pickReceiptPdf,
                onClear: () => setState(() => _receiptImagePath = null),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => unawaited(_submitAndClose()),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.method == _JetonPayMethod.whatsapp
                            ? Icons.chat_rounded
                            : Icons.payment_rounded,
                      ),
                label: Text(
                  _submitting ? 'Gönderiliyor…' : 'Ödeme Bildir',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.method == _JetonPayMethod.whatsapp
                      ? const Color(0xFF25D366)
                      : AppThemeColors.accentPurple,
                  minimumSize: const Size.fromHeight(52),
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

  Future<void> _pickReceiptGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() => _receiptImagePath = file.path);
  }

  Future<void> _pickReceiptCamera() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() => _receiptImagePath = file.path);
  }

  Future<void> _pickReceiptPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    setState(() => _receiptImagePath = path);
  }

  Future<String?> _uploadReceiptIfNeeded() async {
    final path = _receiptImagePath;
    if (path == null || path.isEmpty) return null;
    try {
      return await ref
          .read(paymentReceiptUploadServiceProvider)
          .uploadFile(File(path))
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      return null;
    }
  }

  Future<void> _openPaymentNotifySheet() async {
    final receiptRefCtrl = TextEditingController();
    var localImage = _receiptImagePath;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12081F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ödeme Bildir',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dekont veya ekran görüntüsü ekleyin. Alanlar otomatik doldurulur.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ctx.colors.onSurfaceMuted.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  child: Column(
                    children: [
                      _RowLabel('Jeton:', '${widget.package.coins}'),
                      const Divider(height: 16, color: Colors.white12),
                      _RowLabel('Tutar:', widget.priceText),
                      const Divider(height: 16, color: Colors.white12),
                      _RowLabel('Açıklama:', _userLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (file == null) return;
                    setSheetState(() => localImage = file.path);
                    setState(() => _receiptImagePath = file.path);
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    localImage == null
                        ? 'Dekont / ekran görüntüsü ekle'
                        : 'Görsel seçildi — değiştir',
                  ),
                ),
                if (localImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: FileImage(File(localImage!)),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: receiptRefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ek referans (isteğe bağlı)',
                    hintText: 'Dekont no veya işlem kodu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          final refText = receiptRefCtrl.text.trim();
                          setState(() => _receiptImagePath = localImage);
                          Navigator.pop(ctx);
                          unawaited(
                            _submitAndClose(extraReceiptRef: refText),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeColors.accentPurple,
                    minimumSize: const Size.fromHeight(50),
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
                          'Ödemeyi Bildir',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
    receiptRefCtrl.dispose();
  }

  Future<void> _submitRequest({String? extraReceiptRef}) async {
    String? uploaded;
    if (_receiptImagePath != null && _receiptImagePath!.isNotEmpty) {
      uploaded = await _uploadReceiptIfNeeded();
    }
    final receiptParts = <String>[
      if (uploaded != null && uploaded.isNotEmpty) uploaded,
      if (extraReceiptRef != null && extraReceiptRef.isNotEmpty) extraReceiptRef,
      if (uploaded == null &&
          _receiptImagePath != null &&
          _receiptImagePath!.isNotEmpty)
        'Dekont görseli eklendi (yüklenemedi — admin ile paylaşın)',
    ];
    final receipt = receiptParts.join(' · ');
    final autoNotes =
        'Açıklama: $_userLabel · ${widget.package.coins} jeton · ${widget.priceText}';
    final isMembership = widget.package.id.startsWith('membership_');
    final body = isMembership
        ? buildMembershipPaymentRequest(
            package: widget.package,
            method: _methodApi,
            notes: widget.paymentNotes ?? autoNotes,
            senderLabel: _userLabel,
            receiptReference: receipt.isEmpty ? null : receipt,
          )
        : buildJetonPaymentRequest(
            package: widget.package,
            method: _methodApi,
            notes: '$autoNotes\n${widget.paymentNotes ?? ''}'.trim(),
            senderLabel: _userLabel,
            receiptReference: receipt.isEmpty ? null : receipt,
          );
    await ref.read(walletRepositoryProvider).submitPaymentRequest(body);
    await _prefs.saveLastPackageId(widget.package.id);
    await _prefs.saveLastPaymentMethod(_methodApi);
    ref.refreshWalletCache(force: true);
    ref.invalidate(paymentRequestsNotifierProvider);
    ref.invalidate(adminPaymentRequestsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsListNotifierProvider);
  }

  Future<void> _showWaitDialog() async {
    final isMembership = widget.package.id.startsWith('membership_');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_top_rounded, color: AppThemeColors.coinGold),
        title: const Text('Ödeme bildiriminiz alındı'),
        content: Text(
          isMembership
              ? 'Talebiniz admin ekibine iletildi.\n\n'
                  'Onay süreci genellikle 5–10 dakika sürer. '
                  'Onaylandığında Gold üyeliğiniz aktifleşir ve bildirim alırsınız.'
              : 'Talebiniz admin ekibine iletildi.\n\n'
                  'Onay süreci genellikle 5–10 dakika sürer. '
                  'Onaylandığında jetonlar hesabınıza yansır ve bildirim alırsınız.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAndClose({String? extraReceiptRef}) async {
    setState(() => _submitting = true);
    try {
      await _submitRequest(extraReceiptRef: extraReceiptRef);
      if (!mounted) return;
      if (widget.method == _JetonPayMethod.whatsapp) {
        await _openWhatsAppChat();
      }
      if (!mounted) return;
      await _showWaitDialog();
      if (!mounted) return;
      widget.onDone();
      Navigator.of(context).pop(true);
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
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
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
                      size: 14, color: context.colors.onSurfaceMuted.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text(userLabel, style: TextStyle(fontSize: 12, color: context.colors.onSurfaceMuted)),
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
            child: Text(label, style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 12)),
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
        border: Border.all(color: AppThemeColors.accentPurple.withValues(alpha: 0.35)),
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
        Text(label, style: TextStyle(color: context.colors.onSurfaceMuted)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: valueColor ?? context.colors.onSurface)),
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
            backgroundColor: AppThemeColors.accentPurple,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(email, style: TextStyle(fontSize: 12, color: context.colors.onSurfaceMuted)),
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
              Text(label, style: TextStyle(color: context.colors.onSurfaceMuted)),
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
                  Text('IBAN:', style: TextStyle(color: context.colors.onSurfaceMuted)),
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

class _ReceiptPickerSection extends StatelessWidget {
  const _ReceiptPickerSection({
    required this.imagePath,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickPdf,
    required this.onClear,
  });

  final String? imagePath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickPdf;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isPdf = imagePath?.toLowerCase().endsWith('.pdf') == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dekont Ekle (isteğe bağlı)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri'),
                ),
                OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Kamera'),
                ),
                OutlinedButton.icon(
                  onPressed: onPickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF / Dosya'),
                ),
                if (imagePath != null)
                  TextButton(onPressed: onClear, child: const Text('Kaldır')),
              ],
            ),
            if (imagePath != null) ...[
              const SizedBox(height: 10),
              if (isPdf)
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        imagePath!.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: FileImage(File(imagePath!)),
                    height: 120,
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
