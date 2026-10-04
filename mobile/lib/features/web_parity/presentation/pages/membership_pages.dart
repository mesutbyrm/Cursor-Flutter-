import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../search/domain/entities/search_user_entity.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../../domain/parity_models.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

const _tierColors = <String, Color>{
  'basic': Color(0xFF6B7080),
  'premium': Color(0xFF3B82F6),
  'gold': Color(0xFFF59E0B),
  'diamond': Color(0xFF22D3EE),
  'svip': Color(0xFFEC4899),
};

Color tierColor(String tier) =>
    _tierColors[tier.toLowerCase()] ?? const Color(0xFF8B5CF6);

/// Üyelik karşılaştırma matrisi — `GET /api/memberships/comparison`.
class MembershipComparisonPage extends ConsumerWidget {
  const MembershipComparisonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipComparisonProvider);
    return MockScaffold(
      title: 'Üyelik karşılaştırması',
      body: ParityAsync<MembershipComparison>(
        value: async,
        onRetry: () => ref.invalidate(membershipComparisonProvider),
        isEmpty: (d) => d.features.isEmpty,
        emptyText: 'Karşılaştırma verisi henüz yok',
        builder: (c) => _Matrix(data: c),
      ),
    );
  }
}

class _Matrix extends StatelessWidget {
  const _Matrix({required this.data});

  final MembershipComparison data;

  @override
  Widget build(BuildContext context) {
    final cols = data.tiers;
    final cats = <String>[];
    for (final f in data.features) {
      if (!cats.contains(f.category)) cats.add(f.category);
    }
    const labelW = 150.0;
    const cellW = 74.0;
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: labelW + cellW * cols.length + 4,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [
            Row(
              children: [
                const SizedBox(width: labelW),
                for (final t in cols)
                  SizedBox(
                    width: cellW,
                    child: Center(
                      child: ParityChip(t.name, color: tierColor(t.key)),
                    ),
                  ),
              ],
            ),
            for (final cat in cats) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.onSurfaceMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              for (final f in data.features.where((f) => f.category == cat))
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: mockCardBorder(context)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelW,
                        child: Text(
                          f.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      for (final t in cols)
                        SizedBox(
                          width: cellW,
                          child: Center(
                            child: Text(
                              f.cells[t.key] ?? '—',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: (f.cells[t.key] ?? '') == '🔒'
                                    ? c.onSurfaceMuted
                                    : tierColor(t.key),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Üyelik hediye et — `GET /api/membership/plans`, `POST /api/memberships/gift`.
class MembershipGiftPage extends ConsumerStatefulWidget {
  const MembershipGiftPage({super.key, this.receiverId, this.receiverName});

  final String? receiverId;
  final String? receiverName;

  @override
  ConsumerState<MembershipGiftPage> createState() => _MembershipGiftPageState();
}

class _MembershipGiftPageState extends ConsumerState<MembershipGiftPage> {
  final _search = TextEditingController();
  final _message = TextEditingController();
  MembershipPlanInfo? _plan;
  SearchUserEntity? _receiver;
  var _method = 'jeton';
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final id = widget.receiverId;
    if (id != null && id.isNotEmpty) {
      _receiver = SearchUserEntity(
        id: id,
        name: widget.receiverName ?? 'Kullanıcı',
        username: '',
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final plan = _plan;
    final to = _receiver;
    if (plan == null) {
      parityToast(context, 'Bir üyelik planı seç');
      return;
    }
    if (to == null) {
      parityToast(context, 'Hediye edilecek kişiyi seç');
      return;
    }
    setState(() => _busy = true);
    try {
      final msg = await ref.read(parityApiProvider).giftMembership(
            planId: plan.id,
            receiverId: to.id,
            paymentMethod: _method,
            message: _message.text,
          );
      unawaited(ref.read(walletBalancesProvider.notifier).refresh(force: true));
      if (!mounted) return;
      parityToast(context, msg);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(membershipPlansProvider);
    final results = ref.watch(userSearchProvider);
    final c = context.colors;
    return MockScaffold(
      title: 'Üyelik hediye et',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
        children: [
          Text('1 · Plan', style: _h(c)),
          const SizedBox(height: 6),
          ParityBox<List<MembershipPlanInfo>>(
            value: plans,
            onRetry: () => ref.invalidate(membershipPlansProvider),
            builder: (list) {
              final giftable = list.where((p) => p.giftable).toList();
              if (giftable.isEmpty) {
                return Text(
                  'Hediye edilebilir plan şu an yok.',
                  style: TextStyle(color: c.onSurfaceMuted),
                );
              }
              return Column(
                children: [
                  for (final p in giftable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ParityCard(
                        onTap: () => setState(() => _plan = p),
                        child: Row(
                          children: [
                            Icon(
                              _plan?.id == p.id
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: tierColor(p.tier),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${p.durationDays} gün',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${p.price}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: tierColor(p.tier),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text('2 · Alıcı', style: _h(c)),
          const SizedBox(height: 6),
          if (_receiver != null)
            ParityCard(
              child: Row(
                children: [
                  UserAvatar(url: _receiver!.image, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _receiver!.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _receiver = null),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _search,
              onChanged: (v) =>
                  ref.read(userSearchProvider.notifier).setQuery(v),
              decoration: const InputDecoration(
                hintText: 'İsim veya kullanıcı adı ara',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            results.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (list) => Column(
                children: [
                  for (final u in list.take(8))
                    ListTile(
                      dense: true,
                      leading: UserAvatar(url: u.image, radius: 16),
                      title: Text(u.name),
                      subtitle: Text('@${u.username}'),
                      onTap: () => setState(() => _receiver = u),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text('3 · Ödeme ve mesaj', style: _h(c)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'jeton', label: Text('Jeton')),
              ButtonSegment(value: 'cfc', label: Text('CFC')),
            ],
            selected: {_method},
            onSelectionChanged: (v) => setState(() => _method = v.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Mesaj (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : () => unawaited(_send()),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.card_giftcard_rounded),
            label: const Text('Hediye et'),
          ),
        ],
      ),
    );
  }

  TextStyle _h(AppThemeColors c) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: c.onSurfaceMuted,
      );
}
