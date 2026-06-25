import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../data/services/broadcast_schedule_service.dart';

final broadcastScheduleServiceProvider =
    FutureProvider<BroadcastScheduleService>((ref) async {
  return BroadcastScheduleService.create();
});

class LiveBroadcastSchedulePage extends ConsumerStatefulWidget {
  const LiveBroadcastSchedulePage({super.key});

  @override
  ConsumerState<LiveBroadcastSchedulePage> createState() =>
      _LiveBroadcastSchedulePageState();
}

class _LiveBroadcastSchedulePageState
    extends ConsumerState<LiveBroadcastSchedulePage> {
  final _titleCtrl = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(hours: 2));
  List<ScheduledBroadcast> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final svc = await ref.read(broadcastScheduleServiceProvider.future);
    await svc.checkUpcomingReminders();
    if (!mounted) return;
    setState(() => _items = svc.loadAll());
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final svc = await ref.read(broadcastScheduleServiceProvider.future);
    await svc.schedule(title: _titleCtrl.text, scheduledAt: _when);
    _titleCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yayın planlandı — hatırlatma ayarlandı')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy HH:mm', 'tr_TR');

    return DiscoverSubPage(
      title: 'Yayın Planla',
      subtitle: 'Takipçilerine bildirim ve hatırlatma',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Yayın başlığı',
              hintText: 'Örn: Akşam tarot yayını',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tarih ve saat'),
            subtitle: Text(fmt.format(_when)),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.event_available_rounded),
            label: const Text('Planı kaydet'),
          ),
          const SizedBox(height: 28),
          Text(
            'Planlanan yayınlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Text(
              'Henüz plan yok',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          for (final item in _items) ...[
            Card(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(fmt.format(item.scheduledAt.toLocal())),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final svc =
                        await ref.read(broadcastScheduleServiceProvider.future);
                    await svc.remove(item.id);
                    await _load();
                  },
                ),
                onTap: () => context.push('/live/type'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
