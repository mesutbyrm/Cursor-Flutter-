import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/message_entities.dart';
import '../providers/messages_providers.dart';

/// Gelen kutusunda bekleyen mesaj isteklerini gösterir.
///
/// Gizlilik ayarı nedeniyle doğrudan mesaj alamayan kullanıcıların gönderdiği
/// istekler sunucuda `GET /api/messages` yanıtının `requests` alanında döner;
/// kabul edilene kadar konuşma listesinde görünmezler. Bu yüzden istekler
/// ayrı bir bölümde listelenip buradan kabul/ret edilir.
class MessageRequestsSliver extends ConsumerWidget {
  const MessageRequestsSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingMessageRequestsProvider);
    final items = async.valueOrNull ?? const <MessageRequestEntity>[];
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Mesaj istekleri (${items.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            for (final r in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RequestCard(request: r),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request});

  final MessageRequestEntity request;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  var _busy = false;

  Future<void> _respond({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await respondToMessageRequest(
        ref,
        widget.request.id,
        accept: accept,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'İstek kabul edildi' : 'İstek reddedildi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final colors = context.colors;
    final name = r.senderName.trim();
    final username = (r.senderUsername ?? '').trim();
    final body = (r.message ?? '').trim();
    final title = name.isNotEmpty
        ? name
        : (username.isNotEmpty ? username : 'Kullanıcı');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(url: r.senderImage, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              tooltip: 'Reddet',
              onPressed: () => _respond(accept: false),
              icon: const Icon(Icons.close_rounded),
            ),
            IconButton(
              tooltip: 'Kabul et',
              onPressed: () => _respond(accept: true),
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ],
      ),
    );
  }
}
