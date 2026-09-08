import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';
import '../../data/admin_site_animation_seed_catalog.dart';
import '../widgets/admin_site_animation_preview_backgrounds.dart';
import '../widgets/admin_site_animation_preview_stage.dart';

class AdminSiteAnimationsPreviewPage extends ConsumerStatefulWidget {
  const AdminSiteAnimationsPreviewPage({super.key, this.animation});

  final AdminSiteAnimation? animation;

  @override
  ConsumerState<AdminSiteAnimationsPreviewPage> createState() =>
      _AdminSiteAnimationsPreviewPageState();
}

class _AdminSiteAnimationsPreviewPageState
    extends ConsumerState<AdminSiteAnimationsPreviewPage> {
  AdminSiteAnimation? _selected;
  var _replayTick = 0;
  AdminSiteAnimationPreviewScreen _screen =
      AdminSiteAnimationPreviewScreen.voice;

  @override
  void initState() {
    super.initState();
    _selected = widget.animation;
  }

  void _replay() => setState(() => _replayTick++);

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Önizleme')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    final animations = ref.watch(adminSiteAnimationListProvider).valueOrNull ??
        const <AdminSiteAnimation>[];
    final active = _selected ??
        (animations.isEmpty
            ? null
            : animations.firstWhere(
                (a) => a.isActive,
                orElse: () => animations.first,
              ));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Ekran Önizleme'),
        actions: [
          if (active != null)
            TextButton(
              onPressed: _replay,
              child: const Text('ÖNİZLE'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<AdminSiteAnimationPreviewScreen>(
            value: _screen,
            decoration: const InputDecoration(labelText: 'Referans ekranı'),
            items: AdminSiteAnimationPreviewScreen.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label),
                  ),
                )
                .toList(),
            onChanged: (s) {
              if (s == null) return;
              setState(() => _screen = s);
            },
          ),
          const SizedBox(height: 12),
          if (_screen == AdminSiteAnimationPreviewScreen.voice) ...[
            const Text(
              'Tier giriş testi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tier in AdminSiteAnimationMembership.values)
                  if (tier != AdminSiteAnimationMembership.all)
                    ActionChip(
                      label: Text(tier.label, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        final id = AdminSiteAnimationSeedCatalog
                            .defaultEntranceIds()[tier];
                        if (id == null) return;
                        final match = animations.cast<AdminSiteAnimation?>().firstWhere(
                          (a) => a?.id == id,
                          orElse: () => null,
                        );
                        if (match != null) {
                          setState(() {
                            _selected = match;
                            _replayTick++;
                          });
                        }
                      },
                    ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            value: active?.id,
            decoration: const InputDecoration(labelText: 'Animasyon seç'),
            items: animations
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.isActive ? "Aktif" : "Pasif"})'),
                  ),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selected = animations.firstWhere((a) => a.id == id);
              });
            },
          ),
          const SizedBox(height: 16),
          if (active != null) ...[
            if (!active!.isActive)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pasif animasyon — production\'da Flutter\'a gönderilmez.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            Center(
              child: AdminSiteAnimationPreviewStage(
                key: ValueKey('${active!.id}:$_screen:$_replayTick'),
                animation: active!,
                screen: _screen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              active!.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${active!.category.label} · ${active!.membership.label} · ${active!.durationMs}ms',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
