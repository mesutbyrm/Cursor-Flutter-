import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/fortune_image_input.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../data/fortune_image_capture_config.dart';
import '../providers/fortune_api_providers.dart';
import '../widgets/fortune_image_capture_panel.dart';
import '../widgets/premium_ai/premium_fortune_open_button.dart';
import 'fortune_reading_service.dart';

/// Fal okuma akışı — premium yükleme, yapılandırılmış AI yorum, sonuç sayfası.
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
    FortuneLocalImageInput? localImages,
  }) async {
    if (!context.mounted) return;

    FortuneLocalImageInput? images = localImages;
    if (FortuneImageCaptureConfig.requiresCapture(type) &&
        (images == null || !images.isValidFor(type))) {
      images = await showFortuneImageCaptureSheet(context: context, type: type);
      if (images == null || !images.isValidFor(type)) return;
    }

    final resolvedYesNo = type.kind == FortuneSessionKind.yesNo
        ? (yesNoChoice ?? _rng.nextBool())
        : yesNoChoice;
    final resolvedBirth =
        birthDate ??
        (type.kind == FortuneSessionKind.numberInput
            ? DateTime(1995, 6, 15)
            : null);

    final imageHint = _imageHint(type, images);

    showPremiumFortuneLoading(
      context: context,
      title: _loadingTitle(type, images),
      subtitle: _loadingSubtitle(type, images),
      accent: type.accent,
    );

    FortuneCloudImageInput? cloudImages;
    if (images != null && FortuneImageCaptureConfig.requiresCapture(type)) {
      try {
        cloudImages = await _uploadImages(ref, type, images);
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
        return;
      }
    }

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
                      images: cloudImages,
                      accessToken: accessToken,
                    )) {
              text = update.text;
              fortuneId = update.fortuneId ?? fortuneId;
              if (update.done) break;
            }
            if (text.trim().isNotEmpty) {
              streamed = true;
              usedRemote = true;
              result = _service.enrichFromApiText(
                type: type,
                text: text,
                recordId: fortuneId,
                imageHint: imageHint,
              );
            }
          } catch (_) {
            streamed = false;
          }
        }
        if (!streamed) {
          final remote = await ref.read(fortuneRepositoryProvider).readFortune(
                type: type,
                userInput: userInput,
                yesNoChoice: resolvedYesNo,
                birthDate: resolvedBirth,
                images: cloudImages,
              );
          usedRemote = true;
          result = _service.enrichFromApiText(
            type: type,
            text: remote.detail,
            summary: remote.summary,
            recordId: remote.recordId,
            luckyNumber: remote.luckyNumber,
            luckyColor: remote.luckyColor,
            imageHint: imageHint,
          );
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 1400));
        result = _service.generate(
          type,
          userInput: userInput,
          yesNoChoice: resolvedYesNo,
          imageHint: imageHint,
        );
        if (images != null && FortuneImageCaptureConfig.requiresCapture(type)) {
          result = result.copyWith(
            detail:
                '${result.detail}\n\n'
                '(Giriş yaparak fotoğraflı AI fal yorumunu alabilirsiniz.)',
          );
        }
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
        imageHint: imageHint,
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
                    imageUrl: finalResult.imageUrl,
                    fortuneText: finalResult.fullText,
                    visualAnalysis: finalResult.visualAnalysis,
                    luckyNumber: finalResult.luckyNumber,
                    luckyColor: finalResult.luckyColor,
                  ),
                );
        if (saved != null) {
          finalResult = finalResult.copyWith(recordId: saved.id);
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

  static String? _imageHint(
    FortuneTypeEntity type,
    FortuneLocalImageInput? images,
  ) {
    if (images == null) return null;
    if (FortuneImageCaptureConfig.isCoffee(type)) {
      return 'fincan içi telve desenleri ve duman çizgileri';
    }
    if (FortuneImageCaptureConfig.isPalm(type)) {
      return 'avuç içi çizgileri ve enerji alanları';
    }
    return null;
  }

  static String _loadingTitle(
    FortuneTypeEntity type,
    FortuneLocalImageInput? images,
  ) {
    if (images != null && FortuneImageCaptureConfig.isCoffee(type)) {
      return 'Kahve falın AI ile hazırlanıyor…';
    }
    if (images != null && FortuneImageCaptureConfig.isPalm(type)) {
      return 'El falın görsel analiz ediliyor…';
    }
    return '${type.title} açılıyor…';
  }

  static String _loadingSubtitle(
    FortuneTypeEntity type,
    FortuneLocalImageInput? images,
  ) {
    if (images != null && FortuneImageCaptureConfig.requiresCapture(type)) {
      return 'Semboller çözülüyor, kişisel yorum yazılıyor (200+ kelime)';
    }
    return 'Kartlar dönüyor, enerjiler senin için birleşiyor';
  }

  static Future<FortuneCloudImageInput> _uploadImages(
    WidgetRef ref,
    FortuneTypeEntity type,
    FortuneLocalImageInput local,
  ) async {
    final uploader = ref.read(fortuneImageUploadServiceProvider);
    if (FortuneImageCaptureConfig.isCoffee(type)) {
      final cup = local.cupPath!;
      final cupPath = await uploader.uploadImageFile(File(cup));
      String? saucerPath;
      if (local.saucerPath != null && local.saucerPath!.trim().isNotEmpty) {
        saucerPath = await uploader.uploadImageFile(File(local.saucerPath!));
      }
      return FortuneCloudImageInput(
        cupImagePath: cupPath,
        saucerImagePath: saucerPath,
      );
    }
    final palmPath = await uploader.uploadImageFile(File(local.palmPath!));
    return FortuneCloudImageInput(
      palmImagePath: palmPath,
      hand: local.hand,
    );
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
