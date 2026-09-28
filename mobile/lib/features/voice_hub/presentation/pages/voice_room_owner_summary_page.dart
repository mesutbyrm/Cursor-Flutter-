import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../gifts/domain/session_gift_summary.dart';
import '../../../profile/data/jeton_packages_catalog.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/voice_session_visitors_provider.dart';

/// Oda sahibinin çıkışta gördüğü özet verisi.
class VoiceRoomOwnerSummaryData {
  const VoiceRoomOwnerSummaryData({
    required this.roomTitle,
    required this.startedAt,
    required this.endedAt,
    required this.visitors,
    required this.senders,
    required this.totalGrossJeton,
    required this.estimatedOwnerNetJeton,
  });

  final String roomTitle;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<VoiceSessionVisitor> visitors;
  final List<SessionGiftSenderRow> senders;
  final int totalGrossJeton;

  /// Cüzdan okunamazsa gösterilen yerel tahmin.
  final int estimatedOwnerNetJeton;
}

/// Sahibin bu oturumdaki gerçek kazancı: `gift_commission` + `gift_received`
/// hareketleri (oturum başlangıcından sonra, açıklamasında oda adı geçen).
int ownerSessionEarningsFromTransactions({
  required Iterable<({int amount, String type, String? description, DateTime? at})> txs,
  required DateTime since,
  required String roomTitle,
}) {
  final title = roomTitle.trim().toLowerCase();
  final from = since.subtract(const Duration(seconds: 5));
  var sum = 0;
  for (final t in txs) {
    if (t.amount <= 0) continue;
    if (t.type != 'gift_commission' && t.type != 'gift_received') continue;
    final at = t.at;
    if (at == null || at.isBefore(from)) continue;
    final desc = t.description?.toLowerCase() ?? '';
    if (title.isNotEmpty && !desc.contains(title)) continue;
    sum += t.amount;
  }
  return sum;
}

Future<void> showVoiceRoomOwnerSummaryPage(
  BuildContext context,
  VoiceRoomOwnerSummaryData data,
) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => VoiceRoomOwnerSummaryPage(data: data),
    ),
  );
}

class VoiceRoomOwnerSummaryPage extends ConsumerStatefulWidget {
  const VoiceRoomOwnerSummaryPage({super.key, required this.data});

  final VoiceRoomOwnerSummaryData data;

  @override
  ConsumerState<VoiceRoomOwnerSummaryPage> createState() =>
      _VoiceRoomOwnerSummaryPageState();
}

class _VoiceRoomOwnerSummaryPageState
    extends ConsumerState<VoiceRoomOwnerSummaryPage> {
  static const _bg = Color(0xFF0E0A1A);
  static const _card = Color(0xFF1B1430);
  static const _muted = Color(0xFFC9C3DA);
  static const _gold = Color(0xFFFFD54F);

  int? _earned;
  int? _balance;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final snap = await ref
          .read(economyWalletRemoteProvider)
          .fetchWallet(limit: 100, currency: 'jeton');
      if (!mounted) return;
      if (snap != null) {
        final earned = ownerSessionEarningsFromTransactions(
          txs: snap.transactions.map(
            (t) => (
              amount: t.amount,
              type: t.type,
              description: t.description,
              at: DateTime.tryParse(t.createdAt ?? '')?.toLocal(),
            ),
          ),
          since: widget.data.startedAt,
          roomTitle: widget.data.roomTitle,
        );
        setState(() {
          _earned = earned;
          _balance = snap.jeton;
        });
      }
    } catch (_) {
      // Cüzdan okunamazsa yerel tahmin gösterilir.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h sa $m dk';
    if (m > 0) return '$m dk $s sn';
    return '$s sn';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final rate = ref.watch(walletBalancesProvider).valueOrNull?.jetonTlRate ??
        kDefaultJetonTlRate;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    String tl(int j) => '${(j * rate).toStringAsFixed(2)} ₺';
    final earned = _earned ?? data.estimatedOwnerNetJeton;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Oda özeti'),
        leading: IconButton(
          tooltip: 'Kapat',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            data.roomTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oturum süresi: ${_duration(data.endedAt.difference(data.startedAt))}',
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFB832FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Size kalan',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _loading
                    ? const SizedBox(
                        height: 34,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Text(
                        '$earned $jetonLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                Text(
                  tl(earned),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_loading && _earned == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Cüzdan okunamadı — tahmini tutar',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(
                  Icons.login_rounded,
                  'Giren kişi',
                  '${data.visitors.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  Icons.card_giftcard_rounded,
                  'Atılan hediye',
                  '${data.totalGrossJeton} $jetonLabel',
                ),
              ),
            ],
          ),
          if (_balance != null) ...[
            const SizedBox(height: 10),
            _stat(
              Icons.account_balance_wallet_rounded,
              'Güncel bakiye',
              '$_balance $jetonLabel · ${tl(_balance!)}',
            ),
          ],
          const SizedBox(height: 22),
          _sectionTitle('Kim ne kadar jeton attı'),
          if (data.senders.isEmpty)
            _empty('Bu oturumda hediye atılmadı.')
          else
            for (final s in data.senders)
              _row(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3A2A5C),
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                title: s.displayName,
                subtitle: s.giftCount > 0 ? '${s.giftCount} hediye' : null,
                trailing: '${s.grossJeton} $jetonLabel\n${tl(s.grossJeton)}',
              ),
          const SizedBox(height: 22),
          _sectionTitle('Odaya kimler girdi (${data.visitors.length})'),
          if (data.visitors.isEmpty)
            _empty('Bu oturumda odaya kimse girmedi.')
          else
            for (final v in data.visitors)
              _row(
                leading: UserAvatar(url: v.image, radius: 20),
                title: v.name,
              ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _gold, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: _muted, fontSize: 14)),
      );

  Widget _row({
    required Widget leading,
    required String title,
    String? subtitle,
    String? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
