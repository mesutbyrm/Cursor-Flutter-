#!/usr/bin/env python3
"""Extract live_broadcast_room_page build sections into part files."""
from pathlib import Path

PAGE = Path("mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart")

def main():
    text = PAGE.read_text()
    if "part 'live_broadcast_room_listeners.part.dart'" in text:
        print("already split")
        return

    start = text.find("    if (hasStream && s.isHost) {\n      ref.listen(coBroadcastProvider")
    end = text.find("    final pkExtras = _pkBattleExtras")
    if start < 0 or end < 0:
        raise SystemExit(f"listener markers not found {start} {end}")

    block = text[start:end]
    indented = "\n".join(("    " + ln if ln.strip() else ln) for ln in block.splitlines())
    listeners = (
        "part of 'live_broadcast_room_page.dart';\n\n"
        "extension _LiveBroadcastRoomBuildListeners on _LiveBroadcastRoomPageState {\n"
        "  void registerLiveBuildListeners({\n"
        "    required LiveBroadcastSession s,\n"
        "    required String? streamId,\n"
        "    required bool hasStream,\n"
        "    required LiveVideoPkState? pkState,\n"
        "  }) {\n"
        f"{indented}\n"
        "  }\n"
        "}\n"
    )
    PAGE.parent.joinpath("live_broadcast_room_listeners.part.dart").write_text(listeners)

    replacement = (
        "    registerLiveBuildListeners(\n"
        "      s: s,\n"
        "      streamId: streamId,\n"
        "      hasStream: hasStream,\n"
        "      pkState: pkState,\n"
        "    );\n\n"
    )
    text = text[:start] + replacement + text[end:]

    stack_start = text.find("        body: Stack(\n          fit: StackFit.expand,\n          children: [")
    stack_end = text.find("          ],\n        ),\n      ),\n      ),\n      ),\n    );\n  }\n}")
    if stack_start < 0:
        stack_end = text.find("          ],\n        ),\n      ),\n      ),\n      ),\n    );\n  }\n}")
    if stack_start < 0 or stack_end < 0:
        raise SystemExit(f"stack markers {stack_start} {stack_end}")

    inner_start = stack_start + len("        body: Stack(\n          fit: StackFit.expand,\n          children: [")
    inner = text[inner_start:stack_end]
    inner_indented = "\n".join(("      " + ln if ln.strip() else ln) for ln in inner.splitlines())
    overlay = (
        "part of 'live_broadcast_room_page.dart';\n\n"
        "extension _LiveBroadcastRoomOverlayStack on _LiveBroadcastRoomPageState {\n"
        "  List<Widget> buildLiveOverlayStack({\n"
        "    required BuildContext context,\n"
        "    required LiveBroadcastSession s,\n"
        "    required String? streamId,\n"
        "    required bool hasStream,\n"
        "    required LiveRoomState roomState,\n"
        "    required LiveGiftController giftCtrl,\n"
        "    required GiftSessionState giftSession,\n"
        "    required dynamic activeGift,\n"
        "    required UserEntity? user,\n"
        "    required LiveRoomInteractionState interaction,\n"
        "    required LiveVideoPkState? pkState,\n"
        "    required String pkStatus,\n"
        "    required Map<String, dynamic>? pkExtras,\n"
        "    required int? balance,\n"
        "    required LiveBroadcastSettingsState broadcastSettings,\n"
        "    required CoBroadcastState coBroadcast,\n"
        "    required bool hasCoGuests,\n"
        "    required AsyncValue tournamentsAsync,\n"
        "    required int? tournamentRank,\n"
        "    required LiveHostRankInfo? hostRank,\n"
        "    required double top,\n"
        "    required dynamic fortuneReqState,\n"
        "  }) {\n"
        f"    return [\n{inner_indented}\n    ];\n"
        "  }\n"
        "}\n"
    )
    PAGE.parent.joinpath("live_broadcast_room_overlay_stack.part.dart").write_text(overlay)

    stack_call = (
        "        body: Stack(\n"
        "          fit: StackFit.expand,\n"
        "          children: buildLiveOverlayStack(\n"
        "            context: context,\n"
        "            s: s,\n"
        "            streamId: streamId,\n"
        "            hasStream: hasStream,\n"
        "            roomState: roomState,\n"
        "            giftCtrl: giftCtrl,\n"
        "            giftSession: giftSession,\n"
        "            activeGift: activeGift,\n"
        "            user: user,\n"
        "            interaction: interaction,\n"
        "            pkState: pkState,\n"
        "            pkStatus: pkStatus,\n"
        "            pkExtras: pkExtras,\n"
        "            balance: balance,\n"
        "            broadcastSettings: broadcastSettings,\n"
        "            coBroadcast: coBroadcast,\n"
        "            hasCoGuests: hasCoGuests,\n"
        "            tournamentsAsync: tournamentsAsync,\n"
        "            tournamentRank: tournamentRank,\n"
        "            hostRank: hostRank,\n"
        "            top: top,\n"
        "            fortuneReqState: fortuneReqState,\n"
        "          ),\n"
        "        ),\n"
    )
    text = text[:stack_start] + stack_call + text[stack_end + len("          ],\n        ),"):]

    marker = "/// Premium 2026 canlı yayın"
    idx = text.find(marker)
    text = (
        text[:idx]
        + "part 'live_broadcast_room_listeners.part.dart';\n"
        + "part 'live_broadcast_room_overlay_stack.part.dart';\n\n"
        + text[idx:]
    )
    PAGE.write_text(text)
    print("split ok")


if __name__ == "__main__":
    main()
