import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../domain/pk/live_pk_side_resolver.dart';
import '../../gifts/providers/live_gift_providers.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/live_gift_catalog.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/providers/gift_providers.dart';
import '../../../../gifts/presentation/widgets/gift_staff_finance_prompt.dart';
import '../../../domain/entities/live_gift_type.dart';
import '../../gifts/live_gift_controller.dart';

class PkGiftTarget {
  const PkGiftTarget({
    required this.userId,
    required this.displayName,
    this.isSelf = false,
  });

  final String userId;
  final String displayName;
  final bool isSelf;
}

/// PK — iki yayıncı + (uygunsa) kendim hedefi.
Future<void> showPkLiveGiftPicker(
  BuildContext context,
  WidgetRef ref, {
  required String streamId,
  required Map<String, dynamic>? battle,
  required String myStreamId,
  String? myUserId,
  bool amBroadcaster = false,
}) async {
  final layout = resolveLivePkSplitLayout(
    battle: battle,
    myStreamId: myStreamId,
    myUserId: myUserId,
    amBroadcaster: amBroadcaster,
  );
  final me = myUserId?.trim() ?? '';
  final targets = <PkGiftTarget>[
    PkGiftTarget(
      userId: layout.left.userId ?? '',
      displayName: layout.left.label,
    ),
    PkGiftTarget(
      userId: layout.right.userId ?? '',
      displayName: layout.right.label,
    ),
  ];
  if (me.isNotEmpty) {
    final onLeft = layout.left.userId == me;
    final onRight = layout.right.userId == me;
    if (onLeft || onRight) {
      targets.add(
        PkGiftTarget(
          userId: me,
          displayName: 'Kendim',
          isSelf: true,
        ),
      );
    }
  }
  final pkId = battle?['id']?.toString() ?? battle?['battleId']?.toString();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PkGiftPickerBody(
      streamId: streamId,
      targets: targets.where((t) => t.userId.isNotEmpty).toList(),
      pkMatchId: pkId,
    ),
  );
}

class _PkGiftPickerBody extends ConsumerStatefulWidget {
  const _PkGiftPickerBody({
    required this.streamId,
    required this.targets,
    this.pkMatchId,
  });

  final String streamId;
  final List<PkGiftTarget> targets;
  final String? pkMatchId;

  @override
  ConsumerState<_PkGiftPickerBody> createState() => _PkGiftPickerBodyState();
}

class _PkGiftPickerBodyState extends ConsumerState<_PkGiftPickerBody> {
  late String _selectedUserId;
  LiveVideoGiftType? _selectedGift;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.targets.first.userId;
  }

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(liveGiftTypesProvider);
    final target = widget.targets.firstWhere(
      (t) => t.userId == _selectedUserId,
      orElse: () => widget.targets.first,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kime gönderiyorsun?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in widget.targets)
                  ChoiceChip(
                    label: Text(t.isSelf ? 'Kendim' : t.displayName),
                    selected: _selectedUserId == t.userId,
                    onSelected: (_) => setState(() => _selectedUserId = t.userId),
                    selectedColor: const Color(0xFF9B4DFF),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            gifts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (list) {
                if (list.isEmpty) {
                  return const Text('Hediye listesi boş',
                      style: TextStyle(color: Colors.white54));
                }
                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.32,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final g = list[i];
                      final sel = _selectedGift?.id == g.id;
                      return Opacity(
                        opacity: sel ? 1 : 0.85,
                        child: _PkGiftTile(
                          gift: g,
                          onTap: () => setState(() => _selectedGift = g),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selectedGift == null ? null : () => _send(target),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9B4DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _selectedGift == null
                    ? 'Hediye seç'
                    : 'Gönder → ${target.isSelf ? 'Kendim' : target.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(PkGiftTarget target) async {
    final g = _selectedGift;
    if (g == null) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final sender = user?.displayName ?? user?.username ?? 'Kullanıcı';
    final financeMode =
        await resolveGiftStaffFinanceMode(context, ref);
    if (financeMode == null && shouldAskGiftStaffFinanceMode(ref)) {
      return;
    }
    try {
      final result = await ref.read(liveGiftsRemoteProvider).sendGift(
            streamId: widget.streamId,
            giftTypeId: g.id,
            senderName: sender,
            receiverName: target.isSelf ? sender : target.displayName,
            giftName: LiveGiftCatalog.displayName(g),
            unitPrice: g.price,
            senderId: user?.id,
            toUserId: target.userId,
            pkMatchId: widget.pkMatchId,
            isLucky: g.isLucky,
            staffFinanceMode: financeMode,
          );
      final ev = result.event;
      if (ev != null) {
        ref.read(giftSessionProvider(widget.streamId).notifier).onGiftSent(
              ev,
              source: 'api_response',
              isHost: user?.id == target.userId,
            );
        ref.read(liveGiftControllerProvider).ingestLocalEvent(ev);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LiveGiftCatalog.displayName(g)} gönderildi')),
        );
      }
      ref.refreshWalletCache(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _PkGiftTile extends StatelessWidget {
  const _PkGiftTile({required this.gift, required this.onTap});

  final LiveVideoGiftType gift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = gift.iconUrl(Env.siteOrigin);
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: url.isEmpty
                    ? const Icon(Icons.card_giftcard, size: 28)
                    : CanlifalNetworkImage(url: url, fit: BoxFit.contain),
              ),
              Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
