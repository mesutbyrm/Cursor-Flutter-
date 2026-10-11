import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_girlive_bot_config.dart';
import '../providers/admin_girlive_bot_providers.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/staff_access_provider.dart';

/// `GET/PUT /api/admin/girlive-bot` — bot aç/kapa + herkese açık mesaj ayarları.
class AdminGirLiveBotPage extends ConsumerStatefulWidget {
  const AdminGirLiveBotPage({super.key});

  @override
  ConsumerState<AdminGirLiveBotPage> createState() =>
      _AdminGirLiveBotPageState();
}

class _AdminGirLiveBotPageState extends ConsumerState<AdminGirLiveBotPage> {
  AdminGirLiveBotConfig? _draft;
  final _intervalCtrl = TextEditingController(text: '30');
  final _templateCtrls = <String, TextEditingController>{};
  var _saving = false;

  static const _templateKeys = [
    'pk_start',
    'pk_end',
    'pk_draw',
    'jeton_promo',
    'welcome',
    'leave',
  ];

  @override
  void dispose() {
    _intervalCtrl.dispose();
    for (final c in _templateCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _bindDraft(AdminGirLiveBotConfig cfg) {
    _draft = cfg;
    final pm = cfg.publicMessages;
    _intervalCtrl.text = '${pm.minMessageIntervalSec}';
    for (final key in _templateKeys) {
      _templateCtrls.putIfAbsent(key, () => TextEditingController());
      _templateCtrls[key]!.text = pm.templates[key] ?? '';
    }
  }

  AdminGirLiveBotConfig _collectDraft() {
    final base = _draft ?? const AdminGirLiveBotConfig();
    final pm = base.publicMessages;
    final templates = <String, String>{};
    for (final key in _templateKeys) {
      final t = _templateCtrls[key]?.text.trim() ?? '';
      if (t.isNotEmpty) templates[key] = t;
    }
    final nextPm = pm.copyWith(
      minMessageIntervalSec:
          int.tryParse(_intervalCtrl.text.trim()) ?? pm.minMessageIntervalSec,
      templates: templates,
    );
    return base.copyWith(publicMessages: nextPm);
  }

  Future<void> _save() async {
    if (_draft == null || _saving) return;
    setState(() => _saving = true);
    try {
      final next = _collectDraft();
      await ref.read(adminRemoteProvider).updateGirLiveBotConfig(next);
      _draft = next;
      ref.invalidate(adminGirLiveBotConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GirLive Bot ayarları kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin && !access.isFounder) {
      return Scaffold(
        appBar: AppBar(title: const Text('GirLive Bot')),
        body: const Center(
          child: Text('Bu alan yalnızca site yöneticileri içindir.'),
        ),
      );
    }

    final async = ref.watch(adminGirLiveBotConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GirLive Bot'),
        actions: [
          IconButton(
            onPressed: _saving
                ? null
                : () => ref.invalidate(adminGirLiveBotConfigProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiException.userMessage(e)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(adminGirLiveBotConfigProvider),
                  child: const Text('Yeniden dene'),
                ),
              ],
            ),
          ),
        ),
        data: (cfg) {
          if (_draft == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _bindDraft(cfg));
            });
          }
          final d = _draft ?? cfg;
          final pm = d.publicMessages;
          final detailControls = d.publicMessageControlsActive;

          void setDraft(AdminGirLiveBotConfig next) =>
              setState(() => _draft = next);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Genel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SwitchListTile(
                title: const Text('GirLive Bot'),
                subtitle: const Text(
                  'Kapalıyken bot tetikleyicileri ve otomatik mesajlar çalışmaz.',
                ),
                value: d.enabled,
                onChanged: (v) => setDraft(d.copyWith(enabled: v)),
              ),
              SwitchListTile(
                title: const Text('Sesli odalarda bot'),
                value: d.voiceRoomEnabled,
                onChanged: d.enabled
                    ? (v) => setDraft(d.copyWith(voiceRoomEnabled: v))
                    : null,
              ),
              SwitchListTile(
                title: const Text('Canlı yayında bot'),
                value: d.liveStreamEnabled,
                onChanged: d.enabled
                    ? (v) => setDraft(d.copyWith(liveStreamEnabled: v))
                    : null,
              ),
              const Divider(height: 28),
              Text(
                'Herkese açık mesajlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SwitchListTile(
                title: const Text('Otomatik mesajlar'),
                subtitle: const Text('PK, jeton tanıtımı, hoş geldin / görüşürüz'),
                value: pm.enabled,
                onChanged: d.enabled
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages: pm.copyWith(enabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Jeton tanıtım mesajları'),
                value: pm.jetonPromoEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages: pm.copyWith(jetonPromoEnabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('PK başlangıç'),
                value: pm.pkStartEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages: pm.copyWith(pkStartEnabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('PK ara hatırlatma'),
                value: pm.pkMidReminderEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages:
                                pm.copyWith(pkMidReminderEnabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('PK bitiş'),
                value: pm.pkEndEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages: pm.copyWith(pkEndEnabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Geçmiş PK motivasyonu'),
                value: pm.pastPkMotivationEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages:
                                pm.copyWith(pastPkMotivationEnabled: v),
                          ),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Hoş geldin / görüşürüz'),
                value: pm.welcomeLeaveEnabled,
                onChanged: detailControls
                    ? (v) => setDraft(
                          d.copyWith(
                            publicMessages: pm.copyWith(welcomeLeaveEnabled: v),
                          ),
                        )
                    : null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _intervalCtrl,
                enabled: detailControls,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum mesaj aralığı (sn)',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Şablonlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final key in _templateKeys) ...[
                TextField(
                  enabled: detailControls,
                  controller: _templateCtrls.putIfAbsent(
                    key,
                    () => TextEditingController(text: pm.templates[key] ?? ''),
                  ),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: key.replaceAll('_', ' '),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}
