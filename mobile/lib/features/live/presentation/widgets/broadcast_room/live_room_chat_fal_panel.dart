import 'package:flutter/material.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import 'live_fortune_request_form.dart';
import 'live_room_chat_message.dart';
import '../premium_2026/live/live_premium_chat_feed.dart';

/// Sohbet + Fal İsteği sekmeli panel.
class LiveRoomChatFalPanel extends StatefulWidget {
  const LiveRoomChatFalPanel({
    super.key,
    required this.messages,
    required this.onSubmitFortuneRequest,
    this.balance,
    this.initialFortuneType,
    this.showFortuneTab = true,
    this.onMessageLongPress,
    this.canModerate = false,
  });

  final List<LiveRoomChatMessage> messages;
  final Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
  }) onSubmitFortuneRequest;
  final int? balance;
  final String? initialFortuneType;
  final bool showFortuneTab;
  final void Function(LiveRoomChatMessage message)? onMessageLongPress;
  final bool canModerate;

  @override
  State<LiveRoomChatFalPanel> createState() => _LiveRoomChatFalPanelState();
}

class _LiveRoomChatFalPanelState extends State<LiveRoomChatFalPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.showFortuneTab ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showFortuneTab)
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFB832FF),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            tabs: const [
              Tab(text: 'Sohbet'),
              Tab(text: 'Fal İsteği'),
            ],
          ),
        SizedBox(
          height: widget.showFortuneTab ? 220 : 160,
          child: widget.showFortuneTab
              ? TabBarView(
                  controller: _tabs,
                  children: [
                    LivePremiumChatFeed(
                      messages: widget.messages,
                      onMessageLongPress: widget.onMessageLongPress,
                      canModerate: widget.canModerate,
                    ),
                    SingleChildScrollView(
                      child: LiveFortuneRequestForm(
                        balance: widget.balance,
                        initialFortuneType: widget.initialFortuneType,
                        onSubmit: widget.onSubmitFortuneRequest,
                      ),
                    ),
                  ],
                )
              : LivePremiumChatFeed(
                  messages: widget.messages,
                  onMessageLongPress: widget.onMessageLongPress,
                  canModerate: widget.canModerate,
                ),
        ),
      ],
    );
  }
}
