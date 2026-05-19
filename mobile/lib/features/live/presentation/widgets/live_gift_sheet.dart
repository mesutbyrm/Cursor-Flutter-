import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/live_gifts_remote_datasource.dart';
import '../../domain/entities/live_gift_type.dart';

final _liveGiftsRemoteProvider = Provider<LiveGiftsRemoteDataSource>((ref) {
  return LiveGiftsRemoteDataSource(ref.watch(dioProvider));
});

final liveGiftTypesProvider =
    FutureProvider.autoDispose<List<LiveVideoGiftType>>((ref) async {
  return ref.watch(_liveGiftsRemoteProvider).fetchGiftTypes();
});

Future<void> showLiveGiftPicker(
  BuildContext context,
  WidgetRef ref, {
  required String streamId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final gifts = ref.watch(liveGiftTypesProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scroll) {
              return gifts.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(ApiException.userMessage(e)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Hediye listesi boş'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'Hediye gönder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Kredi cüzdanından düşer. Site ile aynı hediye türleri.',
                          style: TextStyle(color: AppTheme.muted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final g = list[i];
                            return _GiftTile(
                              gift: g,
                              onTap: () async {
                                try {
                                  await ref
                                      .read(_liveGiftsRemoteProvider)
                                      .sendGift(
                                        streamId: streamId,
                                        giftTypeId: g.id,
                                      );
                                  if (context.mounted) {
                                    ref.invalidate(coinBalanceProvider);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${g.name} gönderildi'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ApiException.userMessage(e),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift, required this.onTap});

  final LiveVideoGiftType gift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = gift.iconUrl(Env.siteOrigin);
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: url.isEmpty
                    ? const Icon(Icons.card_giftcard, size: 36)
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.card_giftcard),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                '${gift.price} kredi',
                style: const TextStyle(color: AppTheme.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
