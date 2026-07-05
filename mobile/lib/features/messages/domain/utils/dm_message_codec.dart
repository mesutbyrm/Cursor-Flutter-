/// DM wire format — alıntı, ilet ve sesli arama sinyalleri (görünmez önek).
abstract final class DmMessageCodec {
  static const _prefix = '\u2063';

  static bool isSystemPayload(String text) {
    final t = text.trim();
    return t.startsWith('$_prefix') ||
        t.startsWith('⟦') ||
        t.contains('⟦vc:');
  }

  static String wrapReply({
    required String replyId,
    required String replyText,
    required String body,
  }) {
    final quote = replyText.length > 120
        ? '${replyText.substring(0, 120)}…'
        : replyText;
    return '$_prefix{"reply":{"id":"$replyId","text":${_escapeJson(quote)}}}\u2063$body';
  }

  static String wrapForward({
    required String body,
    required String fromLabel,
  }) {
    return '$_prefix{"fwd":"${_escapeJson(fromLabel)}"}\u2063$body';
  }

  static String callInvite({
    required String callId,
    required String channelId,
  }) =>
      '⟦vc:i:$callId:$channelId⟧';

  static String callAccept(String callId) => '⟦vc:a:$callId⟧';

  static String callReject(String callId) => '⟦vc:r:$callId⟧';

  static DmCallSignal? parseCallSignal(String text) {
    final t = text.trim();
    if (!t.startsWith('⟦vc:')) return null;
    final inner = t.replaceFirst('⟦vc:', '').replaceFirst('⟧', '');
    final parts = inner.split(':');
    if (parts.length < 2) return null;
    final kind = parts[0];
    final callId = parts[1];
    if (callId.isEmpty) return null;
    return switch (kind) {
      'i' => DmCallSignal.invite(
          callId: callId,
          channelId: parts.length > 2 ? parts[2] : callId,
        ),
      'a' => DmCallSignal.accept(callId: callId),
      'r' => DmCallSignal.reject(callId: callId),
      _ => null,
    };
  }

  static DmParsedMessage parseDisplay(String raw) {
    var text = raw;
    DmReplyMeta? reply;
    String? forwardedFrom;

    if (text.startsWith(_prefix)) {
      final end = text.indexOf(_prefix, _prefix.length);
      if (end > 0) {
        final meta = text.substring(_prefix.length, end);
        text = text.substring(end + _prefix.length);
        reply = _parseReplyMeta(meta);
        forwardedFrom = _parseForwardMeta(meta);
      }
    }

    return DmParsedMessage(
      displayText: text.trim(),
      reply: reply,
      forwardedFrom: forwardedFrom,
    );
  }

  static DmReplyMeta? _parseReplyMeta(String meta) {
    final idMatch = RegExp(r'"id"\s*:\s*"([^"]+)"').firstMatch(meta);
    final textMatch = RegExp(r'"text"\s*:\s*"((?:\\.|[^"\\])*)"').firstMatch(meta);
    if (idMatch == null || textMatch == null) return null;
    return DmReplyMeta(
      id: idMatch.group(1)!,
      text: _unescapeJson(textMatch.group(1)!),
    );
  }

  static String? _parseForwardMeta(String meta) {
    final m = RegExp(r'"fwd"\s*:\s*"((?:\\.|[^"\\])*)"').firstMatch(meta);
    if (m == null) return null;
    return _unescapeJson(m.group(1)!);
  }

  static String _escapeJson(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');

  static String _unescapeJson(String s) =>
      s.replaceAll('\\n', '\n').replaceAll('\\"', '"').replaceAll('\\\\', '\\');
}

class DmReplyMeta {
  const DmReplyMeta({required this.id, required this.text});

  final String id;
  final String text;
}

class DmParsedMessage {
  const DmParsedMessage({
    required this.displayText,
    this.reply,
    this.forwardedFrom,
  });

  final String displayText;
  final DmReplyMeta? reply;
  final String? forwardedFrom;
}

sealed class DmCallSignal {
  const DmCallSignal({required this.callId});

  final String callId;

  const factory DmCallSignal.invite({
    required String callId,
    required String channelId,
  }) = DmCallInviteSignal;

  const factory DmCallSignal.accept({required String callId}) =
      DmCallAcceptSignal;

  const factory DmCallSignal.reject({required String callId}) =
      DmCallRejectSignal;
}

final class DmCallInviteSignal extends DmCallSignal {
  const DmCallInviteSignal({required super.callId, required this.channelId});

  final String channelId;
}

final class DmCallAcceptSignal extends DmCallSignal {
  const DmCallAcceptSignal({required super.callId});
}

final class DmCallRejectSignal extends DmCallSignal {
  const DmCallRejectSignal({required super.callId});
}
