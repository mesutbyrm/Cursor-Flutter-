import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// Falcı sohbet oturumları (kullanıcı ve falcı görünümü).
class TellerChatListPage extends ConsumerStatefulWidget {
  const TellerChatListPage({super.key});

  @override
  ConsumerState<TellerChatListPage> createState() => _TellerChatListPageState();
}

class _TellerChatListPageState extends ConsumerState<TellerChatListPage> {
  bool _asTeller = false;

  String get _path => '${ApiEndpoints.tellerChatSessions}?role=${_asTeller ? 'teller' : 'user'}';

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(parityListProvider(_path));
    return MockScaffold(
      title: 'Falcı Sohbetleri',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Danışan')),
                ButtonSegment(value: true, label: Text('Falcı')),
              ],
              selected: {_asTeller},
              onSelectionChanged: (s) => setState(() => _asTeller = s.first),
            ),
          ),
          Expanded(
            child: ParityAsync<List<Map<String, dynamic>>>(
              value: v,
              onRetry: () => ref.invalidate(parityListProvider(_path)),
              isEmpty: (d) => d.isEmpty,
              emptyIcon: Icons.chat_bubble_outline_rounded,
              emptyText: 'Henüz falcı sohbetin yok',
              builder: (list) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(parityListProvider(_path)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    final live = asJsonMap(s['liveSession']);
                    final other = _asTeller
                        ? asJsonMap(live['user'])
                        : asJsonMap(live['teller']);
                    final name = (other['name'] ?? other['displayName'] ?? 'Sohbet').toString();
                    final img = (other['image'] ?? other['avatar'])?.toString();
                    final msgs = asJsonList(s['messages']);
                    final unread = asInt(s['unreadCount']);
                    return ParityCard(
                      onTap: () => context.push('/falci-sohbet/${s['id']}'),
                      child: Row(
                        children: [
                          UserAvatar(url: img, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  msgs.isEmpty
                                      ? 'Mesaj yok'
                                      : (msgs.first['content']?.toString() ??
                                          ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (unread > 0)
                            CircleAvatar(
                              radius: 11,
                              child: Text('$unread',
                                  style: const TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TellerChatThreadPage extends ConsumerStatefulWidget {
  const TellerChatThreadPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<TellerChatThreadPage> createState() => _ThreadState();
}

class _ThreadState extends ConsumerState<TellerChatThreadPage> {
  final _ctl = TextEditingController();
  Timer? _poll;
  bool _sending = false;

  String get _path => ApiEndpoints.tellerChatSession(widget.sessionId);

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) ref.invalidate(parityMapProvider(_path));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(parityApiProvider)
          .rawPost(_path, {'content': text, 'messageType': 'text'});
      _ctl.clear();
      ref.invalidate(parityMapProvider(_path));
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(parityMapProvider(_path));
    return MockScaffold(
      title: 'Falcı Sohbeti',
      body: Column(
        children: [
          Expanded(
            child: ParityAsync<Map<String, dynamic>>(
              value: v,
              onRetry: () => ref.invalidate(parityMapProvider(_path)),
              builder: (d) {
                final msgs = asJsonList(d['messages']);
                final myTeller = asJsonMap(
                    asJsonMap(asJsonMap(d['chatSession'])['liveSession'])['teller'])['userId'];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[msgs.length - 1 - i];
                    final fromTeller = m['senderType'] == 'teller';
                    // Falcı kendi mesajı sağda; danışan kendi mesajı sağda.
                    final mine = m['senderId'] != null &&
                        ((fromTeller && myTeller == m['senderId']) ||
                            (!fromTeller && myTeller != m['senderId']));
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m['content']?.toString() ?? '',
                          style: TextStyle(
                            color: mine
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
