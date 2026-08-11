import 'package:canlifal_social/features/gifts/domain/session_gift_summary.dart';
import 'package:canlifal_social/features/gifts/domain/session_summary_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SessionSummaryMessage lines include viewers jeton and duration', () {
    const summary = SessionGiftSummary(
      title: 'Test',
      totalGrossJeton: 500,
      myNetJeton: 250,
      guestNetJeton: 0,
      senders: const [],
    );
    final lines = SessionSummaryMessage.lines(
      summary,
      viewerCount: 12,
      duration: const Duration(minutes: 5, seconds: 30),
      endedLabel: 'Yayın sona erdi',
    );
    expect(lines.first, 'Yayın sona erdi');
    expect(lines.any((l) => l.contains('12 kişi')), isTrue);
    expect(lines.any((l) => l.contains('500 jeton')), isTrue);
    expect(lines.any((l) => l.contains('5 dk')), isTrue);
    expect(lines.any((l) => l.contains('250 jeton')), isTrue);
  });
}
