import 'package:flutter/material.dart';
import '../../domain/entities/compatibility_entity.dart';

class CompatibilityCard extends StatelessWidget {
  final CompatibilityScore compatibility;

  const CompatibilityCard({
    Key? key,
    required this.compatibility,
  }) : super(key: key);

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 55) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final level = compatibility.getCompatibilityLevel();
    final scoreColor = _getScoreColor(compatibility.overallScore);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${compatibility.sign1.turkishName} ♥ ${compatibility.sign2.turkishName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Overall Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Genel Uyum:', style: TextStyle(fontSize: 14)),
                Text(
                  '${compatibility.overallScore}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Compatibility Level
            Text(
              level,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 16),
            // Score Details
            _ScoreBar('Duygusal', compatibility.emotionalScore),
            const SizedBox(height: 8),
            _ScoreBar('Entelektüel', compatibility.intellectualScore),
            const SizedBox(height: 8),
            _ScoreBar('Fiziksel', compatibility.physicalScore),
            const SizedBox(height: 16),
            // Description
            Text(
              compatibility.description,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBar(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(Colors.red, Colors.green, score / 100)!,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$score%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
