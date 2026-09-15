import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../../pk/presentation/widgets/pk_start_sheet.dart';
import '../../domain/entities/live_broadcast_session.dart';

/// Canlı PK daveti — rota uyumu; premium `showPkStartSheet`.
class LivePkInvitePage extends ConsumerStatefulWidget {
  const LivePkInvitePage({super.key, required this.session});

  final LiveBroadcastSession session;

  @override
  ConsumerState<LivePkInvitePage> createState() => _LivePkInvitePageState();
}

class _LivePkInvitePageState extends ConsumerState<LivePkInvitePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId != null && streamId.isNotEmpty) {
      await showPkStartSheet(
        context,
        ref,
        args: PkSessionArgs(contextId: streamId, kind: PkContextKind.live),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın kimliği bulunamadı')),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
