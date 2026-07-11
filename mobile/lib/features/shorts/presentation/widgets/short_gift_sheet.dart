import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/domain/gift_platform.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_catalog.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_api_message.dart';
import 'short_gift_burst.dart';

Future<void> showShortGiftSheet(
  BuildContext context,
  WidgetRef ref,
  ShortVideoEntity video,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    isScrollControlled: true,
    builder: (ctx) => _ShortGiftSheet(video: video),
  );
}

class _ShortGiftSheet extends ConsumerStatefulWidget {
  const _ShortGiftSheet({required this.video});

  final ShortVideoEntity video;

  @override
  ConsumerState<_ShortGiftSheet> createState() => _ShortGiftSheetState();
}

class _ShortGiftSheetState extends ConsumerState<_ShortGiftSheet> {
  List<LiveVideoGiftType> _gifts = const [];
  var _loading = true;
  var _sending = false;
  LiveVideoGiftType? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = LiveGiftsRemoteDataSource(ref.read(dioProvider));
      var list = await ds.fetchGiftTypesFromGiftsApi(
        platform: GiftPlatform.mobile,
      );
      if (list.isEmpty) {
        list = await ds.fetchGiftTypes(platform: GiftPlatform.mobile);
      }
      if (mounted) {
        setState(() {
          _gifts = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final gift = _selected;
    if (gift == null || _sending) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    final senderName = me?.display ?? 'Kullanıcı';
    setState(() => _sending = true);
    try {
      var result = await ref.read(shortsRepositoryProvider).sendGift(
            videoId: widget.video.id,
            giftTypeId: gift.id,
            senderName: senderName,
            senderId: me?.id,
          );
      if (result.event == null) {
        final ds = LiveGiftsRemoteDataSource(ref.read(dioProvider));
        final live = await ds.sendGift(
          streamId: widget.video.id,
          giftTypeId: gift.id,
          senderName: senderName,
          receiverName: widget.video.author?.label ?? 'Yayıncı',
          giftName: gift.name,
          unitPrice: gift.price,
          senderId: me?.id,
        );
        result = ShortGiftSendResult(
          newBalance: live.newBalance,
          event: live.event,
        );
      }
      if (result.newBalance != null) {
        ref.invalidate(coinBalanceProvider);
      }
      if (!mounted) return;
      if (result.event != null) {
        await showShortGiftBurst(context, gift.id);
      }
      if (!mounted) return;
      Navigator.pop(context);
      showShortsSnackBar(context, '${gift.name} gönderildi!');
    } catch (e) {
      if (mounted) {
        showShortsSnackBar(context, shortsErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinBalanceProvider) ?? 0;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Jeton hediyesi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    '$coins jeton',
                    style: const TextStyle(color: Colors.amber, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_gifts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Hediye listesi yüklenemedi.'),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _gifts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final g = _gifts[i];
                    final sel = _selected?.id == g.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = g),
                      child: Container(
                        width: 88,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? Colors.amber
                                : Colors.white.withValues(alpha: 0.12),
                            width: sel ? 2 : 1,
                          ),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              LiveGiftCatalog.emojiById[g.id] ?? '🎁',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            Text(
                              '${g.price}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: (_selected == null || _sending) ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hediye gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
