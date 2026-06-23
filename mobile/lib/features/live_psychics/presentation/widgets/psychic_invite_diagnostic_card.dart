import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/psychics_list_controller.dart';
import '../diagnostics/psychic_invite_diagnostic_provider.dart';
import '../providers/psychic_push_payload.dart';

/// FAZ 1 — falcı cihazında push/davet teşhis kartı.
class PsychicInviteDiagnosticCard extends ConsumerWidget {
  const PsychicInviteDiagnosticCard({super.key});

  static const _ilhamTellerId = 'cmokzl5u900w2od09rpqq2fs9';
  static const _ilhamUserId = 'cmoks76yf00c4ph08ppcoqg98';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final approved = ref.watch(approvedPsychicProvider);
    final profile = approved.profile;
    final lastFilter = ref.watch(psychicInviteDiagnosticProvider);

    final userId = user?.id ?? '—';
    final tellerId = profile?.id ?? '—';
    final tellerUserId = profile?.userId ?? '—';
    final oneSignalExternalId = OneSignalBootstrap.externalUserId ?? '—';
    final isFortuneTeller = profile != null && profile.isUsable;
    final approvedLabel = approved.loading
        ? 'yükleniyor'
        : (profile == null
            ? 'null'
            : 'id=${profile.id}, usable=${profile.isUsable}, src=${approved.lastDiagnostic}');

    final sampleInvite = parsePsychicIncomingLoose(
      {
        'type': 'fortune_session_invite',
        'targetId': 'faz1-sample-session',
        'tellerId': tellerId == '—' ? _ilhamTellerId : tellerId,
        'tellerUserId': tellerUserId == '—' ? _ilhamUserId : tellerUserId,
        'clientName': 'FAZ1 Test Danışan',
      },
      title: 'Canlı fal isteği: FAZ1 Test Danışan',
    );
    final minimalInvite = parsePsychicIncomingLoose(
      {
        'type': 'fortune_session_invite',
        'targetId': 'faz1-minimal-session',
      },
      title: 'Canlı fal isteği: Admin Test',
    );
    final nestedUserTrap = parsePsychicIncomingPayload({
      'type': 'psychic_request_created',
      'sessionId': 'faz1-nested-trap',
      'user': {'userId': userId == '—' ? _ilhamUserId : userId},
    });

    PsychicInvitePresentationDecision? fullDecision;
    PsychicInvitePresentationDecision? minimalDecision;
    PsychicInvitePresentationDecision? trapDecision;
    if (sampleInvite != null) {
      fullDecision = evaluatePsychicIncomingInvite(
        authUserId: user?.id,
        invite: sampleInvite,
        tellerProfileId: profile?.id,
        isFortuneTeller: isFortuneTeller,
      );
    }
    if (minimalInvite != null) {
      minimalDecision = evaluatePsychicIncomingInvite(
        authUserId: user?.id,
        invite: minimalInvite,
        tellerProfileId: profile?.id,
        isFortuneTeller: isFortuneTeller,
      );
    }
    if (nestedUserTrap != null) {
      trapDecision = evaluatePsychicIncomingInvite(
        authUserId: user?.id,
        invite: nestedUserTrap,
        tellerProfileId: profile?.id,
        isFortuneTeller: isFortuneTeller,
      );
    }

    return Card(
      color: Colors.orange.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAZ 1 — Push / Davet Teşhisi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _row('user.id', userId),
            _row('tellerId', tellerId),
            _row('tellerUserId', tellerUserId),
            _row('OneSignal external_id', oneSignalExternalId),
            _row('approvedPsychicProvider', approvedLabel),
            _row('isFortuneTeller', '$isFortuneTeller'),
            const Divider(height: 16),
            _row(
              'shouldPresent (tam push)',
              fullDecision == null
                  ? '—'
                  : '${fullDecision.present} — ${fullDecision.reason}',
            ),
            _row(
              'shouldPresent (minimal push)',
              minimalDecision == null
                  ? '—'
                  : '${minimalDecision.present} — ${minimalDecision.reason}',
            ),
            _row(
              'shouldPresent (nested user trap)',
              trapDecision == null
                  ? '—'
                  : '${trapDecision.present} — ${trapDecision.reason}',
            ),
            if (nestedUserTrap != null)
              _row(
                'nested trap clientId',
                nestedUserTrap.clientId.isEmpty ? '(boş)' : nestedUserTrap.clientId,
              ),
            if (lastFilter != null) ...[
              const Divider(height: 16),
              _row('son filtre kaynağı', lastFilter.source),
              _row('son sessionId', lastFilter.sessionId),
              _row(
                'son shouldPresent',
                '${lastFilter.decision.present} — ${lastFilter.decision.reason}',
              ),
              _row('son zaman', lastFilter.at.toIso8601String()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
