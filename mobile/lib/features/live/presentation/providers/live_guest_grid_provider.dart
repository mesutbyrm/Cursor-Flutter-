import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_guest_layout.dart';
import '../../domain/entities/live_guest_slot.dart';
import '../../domain/live_guest_layout_resolver.dart';

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
    String? rtcUserId,
  }) {
    _upsert(
      slotIndex,
      userId: userId,
      displayName: displayName,
      rtcUserId: rtcUserId,
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

  void syncRemoteUserIds(List<String> userIds) {
    if (state.layout == LiveGuestLayout.solo) return;
    final list = [...state.slots];
    var remoteIdx = 0;
    for (var i = 1; i < list.length && remoteIdx < userIds.length; i++) {
      if (list[i].isEmpty) {
        list[i] = list[i].copyWith(
          rtcUserId: userIds[remoteIdx],
          displayName: 'Konuk ${remoteIdx + 1}',
        );
        remoteIdx++;
      }
    }
    state = state.copyWith(slots: list);
  }

  void syncCoBroadcasters(List<Map<String, dynamic>> guests) {
    final approved = guests.where(_isApprovedCoGuest).toList();
    if (approved.isEmpty) return;
    if (state.layout == LiveGuestLayout.solo) {
      setLayout(resolveGuestLayout(guestCount: approved.length));
    }
    final list = [...state.slots];
    var slot = 1;
    for (final g in approved) {
      if (slot >= list.length) break;
      final userId = g['userId']?.toString() ?? '';
      final name = g['userName']?.toString() ??
          g['displayName']?.toString() ??
          'Konuk $slot';
      if (userId.isEmpty) continue;
      list[slot] = list[slot].copyWith(
        userId: userId,
        displayName: name,
        rtcUserId: _guestRtcUserId(g),
        jetonEarned: parseGuestJeton(g),
      );
      slot++;
    }
    state = state.copyWith(slots: list);
  }

  void setHostJeton(int jeton) {
    _upsert(0, jetonEarned: jeton);
  }

  void reset() {
    state = LiveGuestGridState(
      slots: [const LiveGuestSlot(index: 0, isHost: true)],
    );
  }

  void _upsert(
    int index, {
    String? userId,
    String? displayName,
    String? rtcUserId,
    bool? isHost,
    int? jetonEarned,
  }) {
    final list = [...state.slots];
    while (list.length <= index) {
      list.add(LiveGuestSlot(index: list.length));
    }
    list[index] = list[index].copyWith(
      userId: userId,
      displayName: displayName,
      rtcUserId: rtcUserId,
      isHost: isHost,
      jetonEarned: jetonEarned,
    );
    state = state.copyWith(slots: list);
  }
}

bool _isApprovedCoGuest(Map<String, dynamic> g) {
  final status =
      (g['status'] ?? g['state'] ?? 'approved').toString().toLowerCase();
  return status == 'approved' ||
      status == 'active' ||
      status == 'joined' ||
      status == 'live';
}

String? _guestRtcUserId(Map<String, dynamic> guest) {
  final direct = guest['rtcUserId'] ?? guest['trtcUserId'] ?? guest['userId'];
  if (direct != null && '$direct'.trim().isNotEmpty) {
    return '$direct'.trim();
  }
  final legacy = guest['agoraUid'] ?? guest['uid'];
  if (legacy == null) return null;
  final text = '$legacy'.trim();
  return text.isEmpty ? null : text;
}

final liveGuestGridProvider =
    NotifierProvider<LiveGuestGridNotifier, LiveGuestGridState>(
  LiveGuestGridNotifier.new,
);
