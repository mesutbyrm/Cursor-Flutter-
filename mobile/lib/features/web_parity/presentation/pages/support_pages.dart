import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../domain/parity_models.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

Color _statusColor(String s) => switch (s) {
      'open' => const Color(0xFFF59E0B),
      'pending' => const Color(0xFF3B82F6),
      'resolved' => const Color(0xFF22C55E),
      _ => const Color(0xFF6B7080),
    };

/// Destek taleplerim — `GET /api/support/tickets`.
class SupportTicketsPage extends ConsumerWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);
    return MockScaffold(
      title: 'Destek',
      actions: [
        IconButton(
          tooltip: 'Yeni talep',
          icon: const Icon(Icons.add_comment_rounded),
          onPressed: () async {
            await context.push('/destek/yeni');
            ref.invalidate(supportTicketsProvider);
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(supportTicketsProvider.future),
        child: ParityAsync<List<SupportTicket>>(
          value: tickets,
          onRetry: () => ref.invalidate(supportTicketsProvider),
          isEmpty: (d) => d.isEmpty,
          emptyIcon: Icons.support_agent_rounded,
          emptyText: 'Henüz destek talebin yok.\nSağ üstteki + ile yeni talep aç.',
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = list[i];
              return ParityCard(
                onTap: () async {
                  await context.push('/destek/${t.id}');
                  ref.invalidate(supportTicketsProvider);
                },
                child: Row(
                  children: [
                    const MockIconSquare(
                      icon: Icons.support_agent_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${SupportTicket.categoryLabel(t.category)} · ${t.messageCount} mesaj · ${parityDateLabel(t.lastMessageAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.colors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ParityChip(
                      SupportTicket.statusLabel(t.status),
                      color: _statusColor(t.status),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Yeni destek talebi — `POST /api/support/tickets`.
class SupportCreatePage extends ConsumerStatefulWidget {
  const SupportCreatePage({super.key});

  @override
  ConsumerState<SupportCreatePage> createState() => _SupportCreatePageState();
}

class _SupportCreatePageState extends ConsumerState<SupportCreatePage> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  var _category = 'general';
  var _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.length < 3) {
      parityToast(context, 'Konu en az 3 karakter olmalı');
      return;
    }
    if (message.length < 3) {
      parityToast(context, 'Mesaj en az 3 karakter olmalı');
      return;
    }
    setState(() => _busy = true);
    try {
      final t = await ref.read(parityApiProvider).createSupportTicket(
            subject: subject,
            message: message,
            category: _category,
          );
      ref.invalidate(supportTicketsProvider);
      if (!mounted) return;
      parityToast(context, 'Talebin alındı');
      if (t.id.isNotEmpty) {
        context.pushReplacement('/destek/${t.id}');
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MockScaffold(
      title: 'Yeni destek talebi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in SupportTicket.categories.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _category == e.key,
                  onSelected: (_) => setState(() => _category = e.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subject,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Konu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLength: 4000,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Sorununu anlat',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => unawaited(_submit()),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Talebi gönder'),
          ),
        ],
      ),
    );
  }
}

/// Talep ayrıntısı + yanıt — `GET /api/support/tickets/{id}`, `POST …/messages`.
class SupportDetailPage extends ConsumerStatefulWidget {
  const SupportDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportDetailPage> createState() => _SupportDetailPageState();
}

class _SupportDetailPageState extends ConsumerState<SupportDetailPage> {
  final _reply = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(parityApiProvider).replySupportTicket(widget.ticketId, text);
      _reply.clear();
      ref.invalidate(supportTicketProvider(widget.ticketId));
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Talebi kapat'),
        content: const Text('Bu talep kapatılacak. Yeni mesaj yazarsan yeniden açılmaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kapat')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(parityApiProvider).closeSupportTicket(widget.ticketId);
      ref.invalidate(supportTicketProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(supportTicketProvider(widget.ticketId));
    final ticket = async.valueOrNull;
    return MockScaffold(
      title: ticket?.subject ?? 'Destek talebi',
      actions: [
        if (ticket != null && !ticket.isClosed)
          IconButton(
            tooltip: 'Talebi kapat',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () => unawaited(_close()),
          ),
      ],
      body: ParityAsync<SupportTicket>(
        value: async,
        onRetry: () => ref.invalidate(supportTicketProvider(widget.ticketId)),
        builder: (t) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  ParityChip(
                    SupportTicket.statusLabel(t.status),
                    color: _statusColor(t.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SupportTicket.categoryLabel(t.category),
                    style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: t.messages.length,
                itemBuilder: (_, i) => _Bubble(m: t.messages[i]),
              ),
            ),
            if (t.isClosed)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Bu talep kapatıldı. Yeni bir sorun için yeni talep aç.',
                  style: TextStyle(color: context.colors.onSurfaceMuted),
                ),
              )
            else
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: 'Yanıt yaz…',
                            isDense: true,
                            filled: true,
                            fillColor: mockCardColor(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _busy ? null : () => unawaited(_send()),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});

  final SupportMessage m;

  @override
  Widget build(BuildContext context) {
    final staff = m.fromStaff;
    final c = context.colors;
    return Align(
      alignment: staff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: staff
              ? mockCardColor(context)
              : const Color(0xFF8B5CF6).withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mockCardBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staff ? 'Destek ekibi' : 'Sen',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: staff ? const Color(0xFF3B82F6) : c.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(m.body, style: const TextStyle(fontSize: 14, height: 1.35)),
            const SizedBox(height: 3),
            Text(
              parityDateLabel(m.createdAt),
              style: TextStyle(fontSize: 10.5, color: c.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
