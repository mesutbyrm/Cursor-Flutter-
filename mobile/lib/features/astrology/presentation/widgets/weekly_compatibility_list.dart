import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/zodiac_sign.dart';
import '../providers/astrology_provider.dart';

class WeeklyCompatibilityList extends ConsumerWidget {
  final ZodiacSign sign1;
  final ZodiacSign sign2;

  const WeeklyCompatibilityList({
    Key? key,
    required this.sign1,
    required this.sign2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(
      weeklyCompatibilityProvider((sign1: sign1, sign2: sign2)),
    );

    return weekly.when(
      data: (compatibilities) {
        if (compatibilities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Veri yok'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: compatibilities.length,
          itemBuilder: (context, index) {
            final daily = compatibilities[index];
            final formatter = DateFormat('EEE, dd MMM', 'tr_TR');
            final dateStr = formatter.format(daily.date);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${daily.dailyScore}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      daily.daytip,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (daily.bestHours.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'En iyi saatler: ${daily.bestHours}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}
