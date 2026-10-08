import 'dart:io';

import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_incoming_ingest.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_invite_poll_gate.dart';
import 'package:flutter_test/flutter_test.dart';

PsychicRequestEntity _req(
  String sessionId, {
  PsychicSessionStatus status = PsychicSessionStatus.pending,
}) =>
    PsychicRequestEntity(
      sessionId: sessionId,
      clientId: 'client-1',
      clientName: 'Danışan',
      tellerId: 'teller-1',
      durationMinutes: 10,
      totalJeton: 100,
      fortuneType: 'general',
      status: status,
    );

PsychicIncomingIngestDecision _evaluate({
  required PsychicRequestEntity request,
  required PsychicIncomingIngestGate gate,
  bool alreadyQueued = false,
  bool dismissed = false,
  bool presentingThisSession = false,
}) =>
    PsychicIncomingIngestDecision.evaluate(
      request: request,
      gate: gate,
      alreadyQueued: alreadyQueued,
      dismissed: dismissed,
      presentingThisSession: presentingThisSession,
    );

void main() {
  group('PsychicIncomingHost — SSE self-feedback kaldırıldı', () {
    test('host dosyasında bus.add ve _onSseRequest yok', () {
      final file = File(
        'lib/features/live_psychics/presentation/widgets/psychic_incoming_host.dart',
      );
      expect(file.existsSync(), isTrue);
      final src = file.readAsStringSync();
      expect(src.contains('_onSseRequest'), isFalse,
          reason: 'SSE artık doğrudan _ingestIncomingRequest kullanmalı');
      expect(RegExp(r'\bbus\.add\s*\(').hasMatch(src), isFalse,
          reason: 'Senkron bus self-feedback ANR yapıyordu');
      expect(
        src.contains('onRequest: (req) => _ingestIncomingRequest'),
        isTrue,
        reason: 'SSE callback tek ingestion pipeline\'a bağlı olmalı',
      );
    });
  });

  group('PsychicIncomingIngestDecision', () {
    test('event bus kaynağı simülasyonu — gate ile yalnızca bir kez kabul', () {
      final gate = PsychicIncomingIngestGate();
      final req = _req('sess-bus-1');

      final first = _evaluate(request: req, gate: gate);
      expect(first.accept, isTrue);

      final second = _evaluate(request: req, gate: gate);
      expect(second.accept, isFalse);
      expect(second.reason, 'duplicate');
    });

    test('aynı sessionId iki SSE event — yalnızca bir kabul', () {
      final gate = PsychicIncomingIngestGate();
      final req = _req('sess-sse-dup');

      expect(_evaluate(request: req, gate: gate).accept, isTrue);
      expect(_evaluate(request: req, gate: gate).accept, isFalse);
      expect(gate.hasAccepted('sess-sse-dup'), isTrue);
    });

    test('presenting durumunda tekrar event — kabul edilmez', () {
      final gate = PsychicIncomingIngestGate();
      final req = _req('sess-presenting');

      final decision = _evaluate(
        request: req,
        gate: gate,
        presentingThisSession: true,
      );
      expect(decision.accept, isFalse);
      expect(decision.reason, 'already_presenting');
      expect(gate.hasAccepted('sess-presenting'), isFalse);
    });

    test('terminal status — tekrar gösterilmez', () {
      final gate = PsychicIncomingIngestGate();
      for (final status in [
        PsychicSessionStatus.rejected,
        PsychicSessionStatus.expired,
        PsychicSessionStatus.cancelled,
        PsychicSessionStatus.ended,
      ]) {
        final id = 'sess-${status.name}';
        final decision = _evaluate(
          request: _req(id, status: status),
          gate: gate,
        );
        expect(decision.accept, isFalse, reason: status.name);
        expect(decision.reason, anyOf('not_pending', 'terminal_status'));
      }
    });

    test('senkron recursive bus feedback simülasyonu — ikinci evaluate duplicate', () {
      final gate = PsychicIncomingIngestGate();
      final req = _req('sess-recursion');

      var ingestCalls = 0;
      void ingestOnce() {
        ingestCalls++;
        final decision = _evaluate(request: req, gate: gate);
        if (!decision.accept) return;
        // Eski hata: bus.add(req) → listener aynı stack'te tekrar ingest.
        ingestOnce();
      }

      ingestOnce();
      expect(ingestCalls, 2);
      expect(gate.hasAccepted('sess-recursion'), isTrue);
    });

    test('kuyrukta zaten varken duplicate', () {
      final gate = PsychicIncomingIngestGate();
      final req = _req('sess-queued');
      final decision = _evaluate(
        request: req,
        gate: gate,
        alreadyQueued: true,
      );
      expect(decision.accept, isFalse);
      expect(decision.reason, 'duplicate');
    });
  });

  group('SSE + poll çakışması (PsychicInvitePollGate + ingest gate)', () {
    test('SSE noteSeen sonrası poll aynı sessionId\'yi fresh saymaz', () {
      final pollGate = PsychicInvitePollGate();
      const sessionId = 'sess-sse-then-poll';

      // İlk poll turu (initial): tüm pending döner — henüz SSE yok varsayımı atlanır.
      pollGate.takeNewPendingSessionIds([sessionId]);

      // SSE ingestion path: host her denemede noteSeen çağırır.
      pollGate.noteSeen(sessionId);

      final fresh = pollGate.takeNewPendingSessionIds([sessionId]);
      expect(fresh, isEmpty);

      final ingestGate = PsychicIncomingIngestGate();
      expect(
        _evaluate(request: _req(sessionId), gate: ingestGate).accept,
        isTrue,
      );
      expect(
        _evaluate(request: _req(sessionId), gate: ingestGate).accept,
        isFalse,
      );
    });

    test('SSE önce kabul — poll yine listeleyebilir ama ingest gate duplicate', () {
      final ingestGate = PsychicIncomingIngestGate();
      final pollGate = PsychicInvitePollGate();
      final req = _req('sess-order');

      expect(_evaluate(request: req, gate: ingestGate).accept, isTrue);
      pollGate.noteSeen(req.sessionId);

      // İlk poll turu tüm pending id\'leri döndürür; tekrarı ingest gate keser.
      final freshFromPoll = pollGate.takeNewPendingSessionIds([req.sessionId]);
      expect(freshFromPoll, [req.sessionId]);

      expect(_evaluate(request: req, gate: ingestGate).accept, isFalse);
      expect(_evaluate(request: req, gate: ingestGate).reason, 'duplicate');
    });
  });
}
