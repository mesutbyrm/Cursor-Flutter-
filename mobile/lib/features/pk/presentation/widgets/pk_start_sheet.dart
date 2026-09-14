import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_duration_picker.dart';
import '../../data/pk_models.dart';
import '../providers/pk_session_notifier.dart';

/// PK gönder — aday listesi + süre seçici.
Future<void> showPkStartSheet(
  BuildContext context,
  WidgetRef ref, {
  required PkSessionArgs args,
}) async {
  await ref.read(pkSessionProvider(args).notifier).loadCandidates();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1030),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PkStartSheet(args: args),
  );
}

class _PkStartSheet extends ConsumerStatefulWidget {
  const _PkStartSheet({required this.args});

  final PkSessionArgs args;

  @override
  ConsumerState<_PkStartSheet> createState() => _PkStartSheetState();
}

class _PkStartSheetState extends ConsumerState<_PkStartSheet> {
  var _duration = pkDefaultDurationSeconds;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pkSessionProvider(widget.args));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = session.selfBusy || session.isRateLimited || session.loading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚔️ PK Gönder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            PkDurationPicker(
              selectedSeconds: _duration,
              onChanged: (v) => setState(() => _duration = v),
            ),
            const SizedBox(height: 12),
            if (session.error != null)
              Text(
                session.error!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            if (session.candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Şu an PK yapılabilecek kimse yok',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: session.candidates.length,
                  itemBuilder: (context, index) {
                    final c = session.candidates[index];
                    return _CandidateTile(
                      candidate: c,
                      onTap: busy
                          ? null
                          : () => _invite(c.contextId),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _invite(String targetId) async {
    await ref
        .read(pkSessionProvider(widget.args).notifier)
        .create(targetId, durationSeconds: _duration);
    if (!mounted) return;
    final err = ref.read(pkSessionProvider(widget.args)).error;
    if (err == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PK daveti gönderildi')),
      );
    }
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, this.onTap});

  final PkCandidate candidate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage:
            candidate.image.isNotEmpty ? NetworkImage(candidate.image) : null,
        child: candidate.image.isEmpty
            ? const Icon(Icons.person, color: Colors.white54)
            : null,
      ),
      title: Text(
        candidate.name.isNotEmpty ? candidate.name : 'Yayıncı',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        [
          if (candidate.title.isNotEmpty) candidate.title,
          if (candidate.viewers > 0) '${candidate.viewers} izleyici',
        ].join(' · '),
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
    );
  }
}
