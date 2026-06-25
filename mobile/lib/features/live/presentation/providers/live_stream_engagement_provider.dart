import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivePollOption {
  const LivePollOption({required this.id, required this.label, this.votes = 0});

  final String id;
  final String label;
  final int votes;

  LivePollOption copyWith({int? votes}) =>
      LivePollOption(id: id, label: label, votes: votes ?? this.votes);
}

class LiveStreamPoll {
  const LiveStreamPoll({
    required this.id,
    required this.question,
    required this.options,
    this.closed = false,
  });

  final String id;
  final String question;
  final List<LivePollOption> options;
  final bool closed;

  int get totalVotes => options.fold(0, (a, o) => a + o.votes);
}

class LiveStreamEngagementState {
  const LiveStreamEngagementState({
    this.activePoll,
    this.eventBanner,
    this.lastGiveawayWinner,
    this.violations = const [],
  });

  final LiveStreamPoll? activePoll;
  final String? eventBanner;
  final String? lastGiveawayWinner;
  final List<String> violations;

  LiveStreamEngagementState copyWith({
    LiveStreamPoll? activePoll,
    String? eventBanner,
    String? lastGiveawayWinner,
    List<String>? violations,
    bool clearPoll = false,
    bool clearBanner = false,
    bool clearWinner = false,
  }) {
    return LiveStreamEngagementState(
      activePoll: clearPoll ? null : (activePoll ?? this.activePoll),
      eventBanner: clearBanner ? null : (eventBanner ?? this.eventBanner),
      lastGiveawayWinner:
          clearWinner ? null : (lastGiveawayWinner ?? this.lastGiveawayWinner),
      violations: violations ?? this.violations,
    );
  }
}

class LiveStreamEngagementNotifier extends Notifier<LiveStreamEngagementState> {
  @override
  LiveStreamEngagementState build() => const LiveStreamEngagementState();

  void createPoll({
    required String question,
    required List<String> optionLabels,
  }) {
    if (optionLabels.length < 2) return;
    final id = 'poll-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      activePoll: LiveStreamPoll(
        id: id,
        question: question,
        options: [
          for (var i = 0; i < optionLabels.length; i++)
            LivePollOption(id: '$i', label: optionLabels[i]),
        ],
      ),
    );
  }

  /// Sohbetten `!oy 1` / `!oy 2` ile oy.
  bool tryVoteFromChat(String text, String voterName) {
    final poll = state.activePoll;
    if (poll == null || poll.closed) return false;
    final m = RegExp(r'^!oy\s*(\d+)$', caseSensitive: false).firstMatch(text.trim());
    if (m == null) return false;
    final idx = int.tryParse(m.group(1) ?? '') ?? -1;
    if (idx < 1 || idx > poll.options.length) return false;
    final options = [...poll.options];
    final i = idx - 1;
    options[i] = options[i].copyWith(votes: options[i].votes + 1);
    state = state.copyWith(
      activePoll: LiveStreamPoll(
        id: poll.id,
        question: poll.question,
        options: options,
      ),
    );
    return true;
  }

  void closePoll() {
    final poll = state.activePoll;
    if (poll == null) return;
    state = state.copyWith(
      activePoll: LiveStreamPoll(
        id: poll.id,
        question: poll.question,
        options: poll.options,
        closed: true,
      ),
    );
  }

  void clearPoll() => state = state.copyWith(clearPoll: true);

  void setEventBanner(String? text) {
    state = state.copyWith(
      eventBanner: text,
      clearBanner: text == null || text.isEmpty,
    );
  }

  String? pickGiveawayWinner(List<String> viewerNames) {
    if (viewerNames.isEmpty) return null;
    final winner = viewerNames[Random().nextInt(viewerNames.length)];
    state = state.copyWith(lastGiveawayWinner: winner);
    return winner;
  }

  void logViolation(String description) {
    final list = [...state.violations, description];
    if (list.length > 50) list.removeRange(0, list.length - 50);
    state = state.copyWith(violations: list);
  }
}

final liveStreamEngagementProvider =
    NotifierProvider<LiveStreamEngagementNotifier, LiveStreamEngagementState>(
  LiveStreamEngagementNotifier.new,
);
