import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gift_insights_providers.dart';

/// Efsane İlk Destekçi rozeti — bir bağlamda ilk hediyeyi gönderen kişi.
/// Kimse yoksa gizlenir.
class FirstGifterBadge extends ConsumerWidget {
  const FirstGifterBadge({
    super.key,
    required this.context,
    required this.contextId,
  });

  final String context;
  final String contextId;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final key = (context: context, contextId: contextId);
    final async = ref.watch(firstGifterProvider(key));
    final gifter = async.asData?.value;
    if (gifter == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x55FFD54F), Color(0x33FF8A65)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x88FFD54F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F), size: 15),
          const SizedBox(width: 6),
          const Text(
            'Efsane İlk Destekçi: ',
            style: TextStyle(
              color: Color(0xFFFFE082),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          Flexible(
            child: Text(
              gifter.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
