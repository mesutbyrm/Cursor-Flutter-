import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicAvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const PsychicAvailabilityCalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicAvailabilityCalendarScreen> createState() =>
      _PsychicAvailabilityCalendarScreenState();
}

class _PsychicAvailabilityCalendarScreenState
    extends ConsumerState<PsychicAvailabilityCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  late Map<DateTime, List<TimeSlot>> _availability;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
    _initializeAvailability();
  }

  void _initializeAvailability() {
    _availability = {};

    // Mock data: Add some available slots for next 7 days
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (i % 2 == 0) {
        // Available on even days
        _availability[normalizedDate] = [
          TimeSlot(startTime: '09:00', endTime: '12:00', isBooked: false),
          TimeSlot(startTime: '14:00', endTime: '18:00', isBooked: false),
          TimeSlot(startTime: '20:00', endTime: '23:00', isBooked: false),
        ];
      } else {
        // Partially available on odd days
        _availability[normalizedDate] = [
          TimeSlot(startTime: '10:00', endTime: '13:00', isBooked: false),
          TimeSlot(startTime: '15:00', endTime: '17:00', isBooked: true),
          TimeSlot(startTime: '19:00', endTime: '22:00', isBooked: false),
        ];
      }
    }
  }

  List<TimeSlot> _getAvailabilityForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _availability[normalizedDate] ?? [];
  }

  bool _isDateAvailable(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final slots = _availability[normalizedDate];
    return slots != null && slots.isNotEmpty;
  }

  String _monthName(int month) {
    const names = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return names[month - 1];
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final grid = <int?>[];
    for (int i = 0; i < firstWeekday - 1; i++) {
      grid.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      grid.add(i);
    }

    return Column(
      children: List.generate(
        (grid.length / 7).ceil(),
        (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                7,
                (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final day = cellIndex < grid.length ? grid[cellIndex] : null;

                  if (day == null) {
                    return Container(
                      width: 48,
                      height: 48,
                    );
                  }

                  final date =
                      DateTime(_focusedDate.year, _focusedDate.month, day);
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;
                  final isToday = DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day;
                  final hasAvailability = _isDateAvailable(date);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppThemeColors.accentCyan
                            : isToday
                                ? AppThemeColors.accentCyan
                                    .withValues(alpha: 0.3)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppThemeColors.accentCyan
                                    .withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white.withOpacity(0.87),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (hasAvailability)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddSlotDialog(DateTime date) {
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Zaman Dilimi Ekle',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Başlangıç Saati',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'HH:MM (örn: 09:00)',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bitiş Saati',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'HH:MM (örn: 12:00)',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text('İptal', style: TextStyle(fontSize: 13)),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (startController.text.isNotEmpty &&
                            endController.text.isNotEmpty) {
                          setState(() {
                            final normalizedDate =
                                DateTime(date.year, date.month, date.day);
                            _availability[normalizedDate] ??= [];
                            _availability[normalizedDate]!.add(
                              TimeSlot(
                                startTime: startController.text,
                                endTime: endController.text,
                                isBooked: false,
                              ),
                            );
                            _availability[normalizedDate]!.sort((a, b) =>
                                a.startTime.compareTo(b.startTime));
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Zaman dilimi eklendi'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentCyan,
                      ),
                      child: const Text('Ekle',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecurringDialog() {
    final days = <String>[];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Haftalık Tekrarlayan Saatler',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ...[
                  ('Pazartesi', '09:00 - 18:00'),
                  ('Salı', '09:00 - 18:00'),
                  ('Çarşamba', '09:00 - 18:00'),
                  ('Perşembe', '10:00 - 20:00'),
                  ('Cuma', '10:00 - 20:00'),
                  ('Cumartesi', '14:00 - 22:00'),
                  ('Pazar', 'Kapalı'),
                ].map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day.$1,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text(
                              day.$2,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                    ),
                    child: const Text('Kaydet',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          centerTitle: true,
          title: const Text(
            'Müsaitlik Takvimi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showRecurringDialog,
                    icon: const Icon(Icons.repeat_rounded, size: 18),
                    label: const Text('Haftalık Ayarla'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Hızlı ayrıştırma: Sık zaman dilimlerini sabitle'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
                    label: const Text('Şablonlar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 24),
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        '${_monthName(_focusedDate.month)} ${_focusedDate.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white, size: 24),
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Days of week header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _DayHeader('P'),
                      _DayHeader('S'),
                      _DayHeader('Ç'),
                      _DayHeader('P'),
                      _DayHeader('C'),
                      _DayHeader('C'),
                      _DayHeader('P'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Calendar grid
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time Slots for Selected Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zaman Dilimleri - ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddSlotDialog(_selectedDate),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ekle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_getAvailabilityForDate(_selectedDate).isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 48, color: Colors.white30),
                      const SizedBox(height: 12),
                      Text(
                        'Bu tarih için zaman dilimi yok',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._getAvailabilityForDate(_selectedDate)
                  .map((slot) => _buildTimeSlotCard(slot, _selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: slot.isBooked
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: slot.isBooked
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                slot.isBooked
                    ? Icons.event_busy_outlined
                    : Icons.event_available_outlined,
                color: slot.isBooked ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.startTime} - ${slot.endTime}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.87),
                    ),
                  ),
                  Text(
                    slot.isBooked ? 'Dolu' : 'Müsait',
                    style: TextStyle(
                      fontSize: 11,
                      color: slot.isBooked ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          PopupMenuButton(
            color: Colors.grey[900],
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Düzenle', style: TextStyle(fontSize: 13)),
                  ],
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Düzenleme özelliği yakında'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(fontSize: 13, color: Colors.red)),
                  ],
                ),
                onTap: () {
                  setState(() {
                    final normalizedDate =
                        DateTime(date.year, date.month, date.day);
                    _availability[normalizedDate]?.remove(slot);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;

  const _DayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Center(
        child: Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isBooked;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });
}
