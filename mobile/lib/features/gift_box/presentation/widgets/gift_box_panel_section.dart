import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/entities/gift_box_models.dart';
import '../providers/gift_box_providers.dart';
import '../providers/gift_box_scope_providers.dart';

/// Hediye paneli içinde — BÖLÜM 22 create / join / cancel.
class GiftBoxPanelSection extends ConsumerStatefulWidget {
  const GiftBoxPanelSection({
    super.key,
    required this.scope,
    this.creatorUserId,
    this.onActivity,
  });

  final GiftBoxScope scope;
  final String? creatorUserId;
  final VoidCallback? onActivity;

  @override
  ConsumerState<GiftBoxPanelSection> createState() =>
      _GiftBoxPanelSectionState();
}

class _GiftBoxPanelSectionState extends ConsumerState<GiftBoxPanelSection> {
  int _totalAmount = 100;
  int _winnerCount = 10;
  int _durationSec = 60;
  String _taskType = 'none';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(giftBoxRefreshTickProvider(widget.scope), (_, __) {});
    final snap = ref.watch(giftBoxSnapshotProvider(widget.scope));

    return snap.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppThemeColors.accentPink,
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            ApiException.userMessage(e),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (data) => _buildContent(context, data),
    );
  }

  Widget _buildContent(BuildContext context, GiftBoxListSnapshot data) {
    final active = data.boxes.where((b) => b.isActive).toList();
    final limits = data.limits;
    if (!limits.allowedDurations.contains(_durationSec)) {
      _durationSec = limits.allowedDurations.first;
    }
    _totalAmount = _totalAmount.clamp(limits.minAmount, limits.maxAmount);
    _winnerCount = _winnerCount.clamp(1, limits.maxWinners);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Jetonları kutuya koy; katılanlar görevi tamamlayıp ödülü paylaşır.',
          style: TextStyle(
            fontSize: 12,
            color: context.colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 12),
        if (active.isNotEmpty) ...[
          Text(
            'Aktif kutular',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (final box in active)
            _ActiveBoxCard(
              box: box,
              busy: _busy,
              onJoin: () => _join(box),
              onCancel: box.isOwner ? () => _cancel(box.id) : null,
            ),
          const SizedBox(height: 16),
        ],
        Text(
          'Yeni hediye kutusu',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _AmountRow(
          label: 'Toplam jeton',
          value: _totalAmount,
          min: limits.minAmount,
          max: limits.maxAmount,
          step: 10,
          onChanged: (v) => setState(() => _totalAmount = v),
        ),
        _AmountRow(
          label: 'Kazanan sayısı',
          value: _winnerCount,
          min: 1,
          max: limits.maxWinners,
          step: 1,
          onChanged: (v) => setState(() => _winnerCount = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _durationSec,
          decoration: const InputDecoration(labelText: 'Süre (sn)'),
          items: limits.allowedDurations
              .map((d) => DropdownMenuItem(value: d, child: Text('$d sn')))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _durationSec = v);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _taskType,
          decoration: const InputDecoration(labelText: 'Katılım görevi'),
          items: const [
            ('none', 'Görev yok'),
            ('follow_creator', 'Kutu sahibini takip'),
            ('follow_broadcaster', 'Yayıncıyı takip'),
            ('share', 'Paylaş'),
          ]
              .map(
                (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _taskType = v);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.card_giftcard_rounded),
          label: const Text('Kutu aç'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final body = <String, dynamic>{
        'action': 'create',
        'totalAmount': _totalAmount,
        'winnerCount': _winnerCount,
        'durationSec': _durationSec,
        'taskType': _taskType,
        if (widget.scope.roomId != null && widget.scope.roomId!.isNotEmpty)
          'roomId': widget.scope.roomId,
        if (widget.scope.streamId != null && widget.scope.streamId!.isNotEmpty)
          'streamId': widget.scope.streamId,
        if (_taskType == 'follow_user' &&
            widget.creatorUserId != null &&
            widget.creatorUserId!.isNotEmpty)
          'taskTargetUserId': widget.creatorUserId,
      };
      await ref.read(giftBoxRepositoryProvider).postAction(
            body,
            roomId: widget.scope.roomId,
            streamId: widget.scope.streamId,
          );
      ref.invalidate(giftBoxSnapshotProvider(widget.scope));
      widget.onActivity?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hediye kutusu açıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join(GiftBoxSummary box) async {
    setState(() => _busy = true);
    try {
      if (box.taskType == 'share') {
        final scope = widget.scope.streamId != null ? 'stream' : 'room';
        final targetId = widget.scope.streamId ?? widget.scope.roomId ?? '';
        if (targetId.isNotEmpty) {
          await ref.read(giftBoxRepositoryProvider).recordShare({
            'scope': scope,
            'targetId': targetId,
            'channel': 'in_app',
          });
        }
      }
      final res = await ref.read(giftBoxRepositoryProvider).joinBox(box.id);
      ref.invalidate(giftBoxSnapshotProvider(widget.scope));
      widget.onActivity?.call();
      if (!mounted) return;
      final won = res['isWinner'] == true || res['success'] == true;
      final reward = res['rewardAmount'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            won
                ? 'Tebrikler! Ödül: ${reward ?? '—'} jeton'
                : 'Katılım kaydedildi',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String boxId) async {
    setState(() => _busy = true);
    try {
      await ref.read(giftBoxRepositoryProvider).postAction(
        {'action': 'cancel', 'boxId': boxId},
        roomId: widget.scope.roomId,
        streamId: widget.scope.streamId,
      );
      ref.invalidate(giftBoxSnapshotProvider(widget.scope));
      widget.onActivity?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kutu iptal edildi, jeton iade edildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ActiveBoxCard extends StatelessWidget {
  const _ActiveBoxCard({
    required this.box,
    required this.busy,
    required this.onJoin,
    this.onCancel,
  });

  final GiftBoxSummary box;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${box.totalAmount} jeton · ${box.remainingWinners}/${box.winnerCount} kalan',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${box.remainingSec} sn · ${giftBoxTaskLabel(box.taskType)}',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!box.isOwner && !box.hasJoined)
                  FilledButton(
                    onPressed: busy ? null : onJoin,
                    child: const Text('Katıl'),
                  ),
                if (box.hasJoined)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('Katıldınız'),
                  ),
                if (onCancel != null)
                  TextButton(
                    onPressed: busy ? null : onCancel,
                    child: const Text('İptal'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
