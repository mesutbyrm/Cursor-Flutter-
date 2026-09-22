import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../cfc_arena/data/cfc_arena_repository.dart';
import '../../../cfc_arena/domain/cfc_arena_contest_filters.dart';
import '../../../cfc_arena/presentation/providers/cfc_arena_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin — CFC Arena / sezon yarışmaları (`/api/admin/cfc-arena`).
class AdminCfcArenaPage extends ConsumerStatefulWidget {
  const AdminCfcArenaPage({super.key});

  @override
  ConsumerState<AdminCfcArenaPage> createState() => _AdminCfcArenaPageState();
}

class _AdminCfcArenaPageState extends ConsumerState<AdminCfcArenaPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'broadcaster';
  String _scope = 'seasonal';
  bool _featured = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin && !access.isFounder && !access.canManagePayments) {
      return Scaffold(
        appBar: AppBar(title: const Text('CFC Arena')),
        body: const Center(child: Text('Yarışma yönetimi için admin yetkisi gerekir.')),
      );
    }

    final contests = ref.watch(adminCfcArenaContestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Sezon yarışmaları'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                IconButton(
                  onPressed: () {
                    ref.invalidate(adminCfcArenaContestsProvider);
                    ref.invalidate(cfcArenaContestsProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktif yarışmalar canlı yayın ve sesli odalarda banner olarak görünür. '
                      'Katılım `/api/cfc-arena/join` ile kaydedilir.',
                      style: TextStyle(
                        color: context.colors.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CreateCard(
                      nameCtrl: _nameCtrl,
                      descCtrl: _descCtrl,
                      type: _type,
                      scope: _scope,
                      featured: _featured,
                      saving: _saving,
                      onType: (v) => setState(() => _type = v),
                      onScope: (v) => setState(() => _scope = v),
                      onFeatured: (v) => setState(() => _featured = v),
                      onCreate: () => _createContest(context),
                    ),
                  ],
                ),
              ),
            ),
            contests.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(ApiException.userMessage(e))),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Henüz yarışma yok')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final c = rows[i];
                        final id = cfcContestId(c);
                        final name = (c['name'] ?? 'Yarışma').toString();
                        final status = (c['status'] ?? 'draft').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              '${c['type']} · ${c['scope']} · $status',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) =>
                                  _mutate(context, id, action),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'activate',
                                  child: Text('Yayına al (active)'),
                                ),
                                const PopupMenuItem(
                                  value: 'pause',
                                  child: Text('Duraklat'),
                                ),
                                const PopupMenuItem(
                                  value: 'complete',
                                  child: Text('Bitir'),
                                ),
                              ],
                            ),
                            onTap: id.isEmpty
                                ? null
                                : () => context.push('/cfc-arena/$id'),
                          ),
                        );
                      },
                      childCount: rows.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createContest(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yarışma adı gerekli')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final ends = now.add(const Duration(days: 30));
      final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss'.000Z'");
      await ref.read(cfcArenaRepositoryProvider).adminMutate({
        'action': 'create',
        'name': name,
        'description': _descCtrl.text.trim(),
        'type': _type,
        'scope': _scope,
        'status': 'active',
        'isPublic': true,
        'isFeatured': _featured,
        'startsAt': fmt.format(now),
        'endsAt': fmt.format(ends),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yarışma oluşturuldu / güncellendi')),
      );
      _nameCtrl.clear();
      _descCtrl.clear();
      ref.invalidate(adminCfcArenaContestsProvider);
      ref.invalidate(cfcArenaContestsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _mutate(BuildContext context, String contestId, String action) async {
    if (contestId.isEmpty) return;
    final status = switch (action) {
      'activate' => 'active',
      'pause' => 'paused',
      'complete' => 'completed',
      _ => 'active',
    };
    try {
      await ref.read(cfcArenaRepositoryProvider).adminMutate({
        'action': 'updateStatus',
        'contestId': contestId,
        'status': status,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum: $status')),
      );
      ref.invalidate(adminCfcArenaContestsProvider);
      ref.invalidate(cfcArenaContestsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({
    required this.nameCtrl,
    required this.descCtrl,
    required this.type,
    required this.scope,
    required this.featured,
    required this.saving,
    required this.onType,
    required this.onScope,
    required this.onFeatured,
    required this.onCreate,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String type;
  final String scope;
  final bool featured;
  final bool saving;
  final ValueChanged<String> onType;
  final ValueChanged<String> onScope;
  final ValueChanged<bool> onFeatured;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.colors.surfaceContainer,
        border: Border.all(color: AppThemeColors.accentPink.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yeni sezon yarışması',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Ad'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Açıklama'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Tür'),
            items: const [
              DropdownMenuItem(value: 'broadcaster', child: Text('Yayıncı')),
              DropdownMenuItem(value: 'room', child: Text('Sesli oda')),
              DropdownMenuItem(value: 'individual', child: Text('Bireysel')),
              DropdownMenuItem(value: 'team', child: Text('Takım')),
            ],
            onChanged: (v) => onType(v ?? type),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: scope,
            decoration: const InputDecoration(labelText: 'Kapsam'),
            items: const [
              DropdownMenuItem(value: 'seasonal', child: Text('Sezon')),
              DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
              DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
              DropdownMenuItem(value: 'general', child: Text('Genel')),
            ],
            onChanged: (v) => onScope(v ?? scope),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Öne çıkar (odada banner)'),
            value: featured,
            onChanged: onFeatured,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: saving ? null : onCreate,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: const Text('Oluştur ve yayına al'),
          ),
        ],
      ),
    );
  }
}
