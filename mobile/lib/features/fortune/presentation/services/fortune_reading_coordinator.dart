import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../providers/fortune_api_providers.dart';
import 'fortune_reading_service.dart';

/// Fal okuma akışı — oturum ekranını atlayıp doğrudan sonuç sayfasına gider.
class FortuneReadingCoordinator {
  FortuneReadingCoordinator._();

  static final _service = FortuneReadingService();
  static final _rng = Random();

  static Future<void> openReading({
    required BuildContext context,
    required WidgetRef ref,
    required FortuneTypeEntity type,
    String userInput = '',
    bool? yesNoChoice,
    DateTime? birthDate,
    bool replaceCurrentRoute = false,
  }) async {
    if (!context.mounted) return;

    final resolvedYesNo = type.kind == FortuneSessionKind.yesNo
        ? (yesNoChoice ?? _rng.nextBool())
        : yesNoChoice;
    final resolvedBirth =
        birthDate ??
        (type.kind == FortuneSessionKind.numberInput
            ? DateTime(1995, 6, 15)
            : null);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A0F2E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: type.accent),
              const SizedBox(height: 20),
              Text(
                '${type.title} açılıyor…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kartlar ve enerjiler senin için hazırlanıyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    FortuneReadingResult? result;
    var usedRemote = false;

    try {
      final authed = ref.read(authControllerProvider).valueOrNull;
      if (authed != null) {
        final accessToken = await ref.read(tokenStorageProvider).readAccess();
        var streamed = false;
        if (accessToken != null && accessToken.trim().isNotEmpty) {
          try {
            var text = '';
            String? fortuneId;
            await for (final update
                in ref.read(fortuneRepositoryProvider).streamFortune(
                      type: type,
                      userInput: userInput,
                      yesNoChoice: resolvedYesNo,
                      birthDate: resolvedBirth,
                      accessToken: accessToken,
                    )) {
              text = update.text;
              fortuneId = update.fortuneId ?? fortuneId;
              if (update.done) break;
            }
            if (text.trim().isNotEmpty) {
              streamed = true;
              usedRemote = true;
              result = FortuneReadingResult(
                type: type,
                summary: text.length > 120 ? '${text.substring(0, 120)}…' : text,
                detail: text,
                recordId: fortuneId,
              );
            }
          } catch (_) {
            streamed = false;
          }
        }
        if (!streamed) {
          result = await ref.read(fortuneRepositoryProvider).readFortune(
                type: type,
                userInput: userInput,
                yesNoChoice: resolvedYesNo,
                birthDate: resolvedBirth,
              );
          usedRemote = true;
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        result = _service.generate(
          type,
          userInput: userInput,
          yesNoChoice: resolvedYesNo,
        );
      }
    } catch (e) {
      final msg = ApiException.userMessage(e);
      final lower = msg.toLowerCase();
      final needsPurchase =
          lower.contains('kredi') ||
          lower.contains('jeton') ||
          lower.contains('credit') ||
          lower.contains('bakiye') ||
          (e is ApiException && e.statusCode == 402);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (needsPurchase) {
        if (context.mounted) {
          await _showPurchasePrompt(context, msg);
        }
        return;
      }
      result = _service.generate(
        type,
        userInput: userInput,
        yesNoChoice: resolvedYesNo,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Canlı yorum API geçici yanıt vermedi, hazır yorum gösterildi: $msg',
            ),
          ),
        );
      }
    }

    if (result == null) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      return;
    }

    var finalResult = result;
    final authed = ref.read(authControllerProvider).valueOrNull;
    if (authed != null) {
      try {
        final saved = finalResult.recordId != null && usedRemote
            ? null
            : await ref.read(fortuneRepositoryProvider).save(
                  SaveFortuneInput(
                    type: type.title,
                    slug: type.slug,
                    question: userInput.trim().isEmpty ? null : userInput.trim(),
                    summary: finalResult.summary,
                    detail: finalResult.detail,
                    answer: finalResult.summary,
                    luckyNumber: finalResult.luckyNumber,
                    luckyColor: finalResult.luckyColor,
                  ),
                );
        if (saved != null) {
          finalResult = FortuneReadingResult(
            type: finalResult.type,
            summary: finalResult.summary,
            detail: finalResult.detail,
            luckyNumber: finalResult.luckyNumber,
            luckyColor: finalResult.luckyColor,
            recordId: saved.id,
          );
        }
        ref.invalidate(fortuneHistoryProvider);
      } catch (_) {
        // Yerel sonuç yine gösterilir.
      }
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (replaceCurrentRoute) {
      context.pushReplacement('/fortune/${type.slug}/result', extra: finalResult);
    } else {
      context.push('/fortune/${type.slug}/result', extra: finalResult);
    }
  }

  static Future<void> _showPurchasePrompt(
    BuildContext context,
    String message,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Fal için bakiye gerekiyor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/jeton-store');
                },
                icon: const Icon(Icons.toll_rounded),
                label: const Text('Jeton yükle'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/premium-membership');
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Üyelik avantajlarını gör'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
