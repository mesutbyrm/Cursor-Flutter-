import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_guest_layout.dart';
import '../../domain/entities/live_guest_slot.dart';

class LiveGuestGridState {
  const LiveGuestGridState({
    this.layout = LiveGuestLayout.solo,
    this.slots = const [],
    this.pinnedIndex,
  });

  final LiveGuestLayout layout;
  final List<LiveGuestSlot> slots;
  final int? pinnedIndex;

  LiveGuestGridState copyWith({
    LiveGuestLayout? layout,
    List<LiveGuestSlot>? slots,
    int? pinnedIndex,
    bool clearPin = false,
  }) {
    return LiveGuestGridState(
      layout: layout ?? this.layout,
      slots: slots ?? this.slots,
      pinnedIndex: clearPin ? null : (pinnedIndex ?? this.pinnedIndex),
    );
  }
}

class LiveGuestGridNotifier extends Notifier<LiveGuestGridState> {
  @override
  LiveGuestGridState build() => LiveGuestGridState(
        slots: [const LiveGuestSlot(index: 0, isHost: true)],
      );

  void setLayout(LiveGuestLayout layout) {
    final slots = <LiveGuestSlot>[
      for (var i = 0; i < layout.seats; i++)
        i < state.slots.length
            ? state.slots[i]
            : LiveGuestSlot(index: i, isHost: i == 0),
    ];
    state = state.copyWith(layout: layout, slots: slots, clearPin: true);
  }

  void setHost({required String? userId, required String? name}) {
    _upsert(0, userId: userId, displayName: name, isHost: true);
  }

  void addGuest({
    required int slotIndex,
    required String userId,
    required String displayName,
    int? agoraUid,
  }) {
    _upsert(
      slotIndex,
      userId: userId,
      displayName: displayName,
      agoraUid: agoraUid,
    );
  }

  void removeGuest(int slotIndex) {
    if (slotIndex == 0) return;
    final list = [...state.slots];
    if (slotIndex >= list.length) return;
    list[slotIndex] = LiveGuestSlot(index: slotIndex);
    state = state.copyWith(slots: list);
  }

  void togglePin(int index) {
    state = state.copyWith(
      pinnedIndex: state.pinnedIndex == index ? null : index,
    );
  }

  void toggleGuestMute(int index) {
    final list = [...state.slots];
    if (index >= list.length) return;
    final s = list[index];
    list[index] = s.copyWith(mutedByHost: !s.mutedByHost);
    state = state.copyWith(slots: list);
  }

  void syncRemoteUids(List<int> uids) {
    if (state.layout == LiveGuestLayout.solo) return;
    final list = [...state.slots];
    var remoteIdx = 0;
    for (var i = 1; i < list.length && remoteIdx < uids.length; i++) {
      if (list[i].isEmpty) {
        list[i] = list[i].copyWith(
          agoraUid: uids[remoteIdx],
          displayName: 'Konuk ${remoteIdx + 1}',
        );
        remoteIdx++;
      }
    }
    state = state.copyWith(slots: list);
  }

  void syncCoBroadcasters(List<Map<String, dynamic>> guests) {
    if (state.layout == LiveGuestLayout.solo) return;
    final list = [...state.slots];
    var slot = 1;
    for (final g in guests) {
      if (slot >= list.length) break;
      final userId = g['userId']?.toString() ?? '';
      final name = g['userName']?.toString() ??
          g['displayName']?.toString() ??
          'Konuk $slot';
      if (userId.isEmpty) continue;
      list[slot] = list[slot].copyWith(
        userId: userId,
        displayName: name,
        agoraUid: int.tryParse('${g['agoraUid'] ?? g['uid'] ?? ''}'),
      );
      slot++;
    }
    state = state.copyWith(slots: list);
  }

  void _upsert(
    int index, {
    String? userId,
    String? displayName,
    int? agoraUid,
    bool? isHost,
  }) {
    final list = [...state.slots];
    while (list.length <= index) {
      list.add(LiveGuestSlot(index: list.length));
    }
    list[index] = list[index].copyWith(
      userId: userId,
      displayName: displayName,
      agoraUid: agoraUid,
      isHost: isHost,
    );
    state = state.copyWith(slots: list);
  }
}

final liveGuestGridProvider =
    NotifierProvider<LiveGuestGridNotifier, LiveGuestGridState>(
  LiveGuestGridNotifier.new,
);
