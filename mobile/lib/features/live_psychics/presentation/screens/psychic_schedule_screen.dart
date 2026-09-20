import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Uygunluk Takvimi — Haftalık/aylık açık saatler ve müsaitlik.
class PsychicScheduleScreen extends ConsumerStatefulWidget {
  const PsychicScheduleScreen({super.key});

  @override
  ConsumerState<PsychicScheduleScreen> createState() =>
      _PsychicScheduleScreenState();
}

class _PsychicScheduleScreenState extends ConsumerState<PsychicScheduleScreen> {
  // Mock schedule data: day -> {startTime, endTime, isAvailable}
  final Map<String, Map<String, dynamic>> schedule = {
    'Pazartesi': {
      'startTime': '10:00',
      'endTime': '22:00',
      'isAvailable': true,
    },
    'Salı': {'startTime': '10:00', 'endTime': '22:00', 'isAvailable': true},
    'Çarşamba': {
      'startTime': '14:00',
      'endTime': '22:00',
      'isAvailable': true,
    },
    'Perşembe': {'startTime': '10:00', 'endTime': '22:00', 'isAvailable': true},
    'Cuma': {'startTime': '18:00', 'endTime': '23:59', 'isAvailable': true},
    'Cumartesi': {
      'startTime': '09:00',
      'endTime': '23:59',
      'isAvailable': true,
    },
    'Pazar': {'startTime': '10:00', 'endTime': '22:00', 'isAvailable': false},
  };

  @override
  Widget build(BuildContext context) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Uygunluk Takvimi',
                      subtitle: 'Haftalık açık saatlerinizi düzenleyin',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.check_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Takvim kaydedildi')),
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Info card
                  Card(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_rounded,
                            color: AppThemeColors.accentCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu saatler dışında danışanlar size seans talebinde bulunamaz.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule for each day
                  ...List.generate(days.length, (i) {
                    final day = days[i];
                    final daySchedule = schedule[day] ?? {};
                    final isAvailable = daySchedule['isAvailable'] ?? false;
                    final startTime = daySchedule['startTime'] ?? '09:00';
                    final endTime = daySchedule['endTime'] ?? '22:00';

                    return Column(
                      children: [
                        _ScheduleCard(
                          day: day,
                          startTime: startTime,
                          endTime: endTime,
                          isAvailable: isAvailable,
                          onToggle: (val) {
                            setState(() {
                              schedule[day]?['isAvailable'] = val;
                            });
                          },
                          onStartTimeChange: (time) {
                            setState(() {
                              schedule[day]?['startTime'] = time;
                            });
                          },
                          onEndTimeChange: (time) {
                            setState(() {
                              schedule[day]?['endTime'] = time;
                            });
                          },
                        ),
                        if (i < days.length - 1)
                          const SizedBox(height: 8),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),

                  // Quick actions
                  const Text(
                    'Hızlı Seçenekler',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Tüm Günleri Aç'),
                      onPressed: () {
                        setState(() {
                          for (final day in days) {
                            schedule[day]?['isAvailable'] = true;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tüm Günleri Kapat'),
                      onPressed: () {
                        setState(() {
                          for (final day in days) {
                            schedule[day]?['isAvailable'] = false;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Takvimi Kaydet'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Takvim kaydedildi'),
                          ),
                        );
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.onToggle,
    required this.onStartTimeChange,
    required this.onEndTimeChange,
  });

  final String day;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onStartTimeChange;
  final ValueChanged<String> onEndTimeChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isAvailable
          ? AppThemeColors.accentCyan.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: onToggle,
                  activeColor: AppThemeColors.accentCyan,
                ),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Başlangıç',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            _showTimePickerDialog(
                              context,
                              startTime,
                              onStartTimeChange,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              startTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bitiş',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            _showTimePickerDialog(
                              context,
                              endTime,
                              onEndTimeChange,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              endTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTimePickerDialog(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onTimeChange,
  ) {
    final parts = currentTime.split(':');
    int hour = int.tryParse(parts[0]) ?? 10;
    int minute = int.tryParse(parts[1]) ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saat Seçin'),
        content: SizedBox(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: ListWheelScrollView(
                  itemExtent: 40,
                  onSelectedItemChanged: (idx) => hour = idx,
                  children: List.generate(24, (i) => Center(child: Text('$i'))),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListWheelScrollView(
                  itemExtent: 40,
                  onSelectedItemChanged: (idx) => minute = idx * 5,
                  children: List.generate(
                    12,
                    (i) => Center(child: Text('${i * 5}'.padLeft(2, '0'))),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              onTimeChange('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
              Navigator.pop(ctx);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
