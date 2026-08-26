import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/gift_entity.dart';
import '../providers/gift_providers.dart';

/// Profil / hediye merkezi — kılavuz §9.9 `POST /api/gifts/send`.
Future<void> showDirectGiftSendSheet(
  BuildContext context,
  WidgetRef ref, {
  String? receiverUserId,
  String? receiverName,
  String? initialGiftId,
}) {
  final authed = ref.read(authControllerProvider).valueOrNull;
  if (authed == null) {
    exitGuestToLogin(ref);
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DirectGiftSendSheet(
      receiverUserId: receiverUserId,
      receiverName: receiverName,
      initialGiftId: initialGiftId,
    ),
  );
}

class DirectGiftSendSheet extends ConsumerStatefulWidget {
  const DirectGiftSendSheet({
    super.key,
    this.receiverUserId,
    this.receiverName,
    this.initialGiftId,
  });

  final String? receiverUserId;
  final String? receiverName;
  final String? initialGiftId;

  @override
  ConsumerState<DirectGiftSendSheet> createState() =>
      _DirectGiftSendSheetState();
}

class _DirectGiftSendSheetState extends ConsumerState<DirectGiftSendSheet> {
  late final TextEditingController _userCtrl;
  GiftEntity? _selected;
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userCtrl = TextEditingController(text: widget.receiverName ?? '');
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _selected != null || (widget.initialGiftId?.trim().isNotEmpty ?? false);

  String get _sendLabel {
    final gift = _selected;
    if (gift != null) return '${gift.name} gönder';
    if (widget.initialGiftId?.trim().isNotEmpty == true) return 'Gönder';
    return 'Hediye seç';
  }

  Future<String> _resolveReceiverId() async {
    final preset = widget.receiverUserId?.trim() ?? '';
    if (preset.isNotEmpty) return preset;
    final query = _userCtrl.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (query.isEmpty) {
      throw const ApiException('Alıcı kullanıcı adı gerekli');
    }
    final user = await ref
        .read(canlifalUserApiProvider)
        .lookupByUsername(query);
    if (user.id.isEmpty) {
      throw const ApiException('Kullanıcı bulunamadı');
    }
    return user.id;
  }

  Future<void> _send() async {
    var gift = _selected;
    if (gift == null) {
      final id = widget.initialGiftId?.trim() ?? '';
      if (id.isNotEmpty) {
        final list = ref.read(liveGiftCatalogProvider).valueOrNull ?? const [];
        for (final g in list) {
          if (g.id == id) {
            gift = g;
            break;
          }
        }
      }
    }
    if (gift == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final receiverId = await _resolveReceiverId();
      await ref
          .read(giftRepositoryProvider)
          .sendDirectGift(giftId: gift.id, receiverUserId: receiverId);
      ref.refreshWalletCache(force: true);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${gift.name} gönderildi')));
    } catch (e) {
      final message = ApiException.userMessage(e);
      if (!mounted) return;
      if (isInsufficientJetonMessage(message)) {
        showJetonAwareError(context, message, ref: ref);
      } else {
        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(liveGiftCatalogProvider);
    final knownReceiver = widget.receiverUserId?.trim().isNotEmpty == true;
    final title = knownReceiver && widget.receiverName != null
        ? 'Hediye gönder — ${widget.receiverName}'
        : 'Hediye gönder';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (knownReceiver)
              _ReciprocalBanner(userId: widget.receiverUserId!),
            if (!knownReceiver) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _userCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Alıcı kullanıcı adı',
                  hintStyle: const TextStyle(color: Color(0x88FFFFFF)),
                  filled: true,
                  fillColor: const Color(0xFF1A1030),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    ApiException.userMessage(e),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                data: (gifts) {
                  if (gifts.isEmpty) {
                    return const Center(
                      child: Text(
                        'Katalog boş',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return GridView.builder(
                    itemCount: gifts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, i) {
                      final g = gifts[i];
                      final selected =
                          (_selected?.id ?? widget.initialGiftId) == g.id;
                      return InkWell(
                        onTap: () => setState(() => _selected = g),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1030),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFB388FF)
                                  : const Color(0x22FFFFFF),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child:
                                    g.iconUrl != null && g.iconUrl!.isNotEmpty
                                    ? CanlifalNetworkImage(
                                        url: g.iconUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : Text(
                                        g.iconEmoji ?? '🎁',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                              ),
                              Text(
                                g.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '${g.price}',
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: !_canSend || _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_sendLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciprocalBanner extends ConsumerWidget {
  const _ReciprocalBanner({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reciprocalGiftHintProvider(userId));
    final hint = async.valueOrNull;
    if (hint == null || !hint.show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x332E7D32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x6666BB6A)),
        ),
        child: Text(
          hint.message ?? 'Karşılıklı hediye geçmişiniz var',
          style: const TextStyle(
            color: Color(0xFFC8E6C9),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
