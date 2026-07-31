import 'dart:async';
import 'dart:io';
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
import '../providers/fortune_access_providers.dart';
import '../providers/fortune_birth_profile_provider.dart';
import '../widgets/fortune_image_capture_panel.dart';
import '../widgets/premium_ai/premium_fortune_open_button.dart';
import '../../domain/fortune_access_config.dart';
import 'fortune_access_gate.dart';
import '../widgets/fortune_zodiac_hub_card.dart';
import 'fortune_ambient_audio.dart';
import 'fortune_fullscreen_ad_gate.dart';
import 'fortune_reading_service.dart';
import 'fortune_share_handler.dart';

/// Fal okuma akışı — premium yükleme, yapılandırılmış AI yorum, sonuç sayfası.
class FortuneReadingCoordinator {
  FortuneReadingCoordinator._();

  static final _service = FortuneReadingService();
  static final _rng = Random();

  static const _streamMaxWait = Duration(seconds: 90);
  static const _streamIdleGap = Duration(seconds: 28);

  static Future<FortuneReadingResult?> openReading({
    required BuildContext context,
    required WidgetRef ref,
    required FortuneTypeEntity type,
    String userInput = '',
    bool? yesNoChoice,
    DateTime? birthDate,
    bool replaceCurrentRoute = false,
    FortuneLocalImageInput? localImages,
    bool stayOnPage = false,
  }) async {
    if (!context.mounted) return null;

    FortuneLocalImageInput? images = localImages;
    if (FortuneImageCaptureConfig.requiresCapture(type) &&
        (images == null || !images.isValidFor(type))) {
      images = await showFortuneImageCaptureSheet(context: context, type: type);
      if (images == null || !images.isValidFor(type)) return null;
    }

    final authed = ref.read(authControllerProvider).valueOrNull;
    FortuneAccessGrant? accessGrant;
    if (authed != null) {
      accessGrant = await FortuneAccessGate.request(
        context: context,
        ref: ref,
        type: type,
        isAuthenticated: true,
      );
      if (!context.mounted) return null;
      if (accessGrant == null &&
          ref.read(fortuneAccessServiceProvider).isGateRequired(
                type,
                isAuthenticated: true,
              )) {
        return null;
      }
      if (accessGrant != null) {
        try {
          await ref.read(fortuneAccessServiceProvider).consumeGrant(
                type: type,
                grant: accessGrant,
              );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
          return null;
        }
      }
    }

    final paidWithJeton = accessGrant?.method == FortuneAccessMethod.jeton;
    final skipSecondAd = accessGrant != null &&
        accessGrant.method != FortuneAccessMethod.jeton;
    if (!skipSecondAd &&
        !await FortuneFullscreenAdGate.showBeforeFortune(
          context: context,
          paidWithJeton: paidWithJeton,
          ref: ref,
        )) {
      return null;
    }
    if (!context.mounted) return null;

    final paymentMethod = accessGrant != null
        ? ref.read(fortuneAccessServiceProvider).paymentMethodFor(accessGrant)
        : null;
    final jetonCost = accessGrant?.jetonCost;

    final resolvedYesNo = type.kind == FortuneSessionKind.yesNo
        ? (yesNoChoice ?? _rng.nextBool())
        : yesNoChoice;
    var resolvedBirth = birthDate ?? await _resolveBirthDate(ref, type);
    if (resolvedBirth == null &&
        (type.kind == FortuneSessionKind.numberInput ||
            type.kind == FortuneSessionKind.zodiacWheel ||
            type.slug == 'numeroloji' ||
            type.slug == 'yildiz-haritasi')) {
      await showFortuneBirthProfileSheet(context, ref);
      if (!context.mounted) return null;
      resolvedBirth = birthDate ?? await _resolveBirthDate(ref, type);
      if (resolvedBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğum tarihi ve saati gerekli — lütfen profilinize ekleyin'),
          ),
        );
        return null;
      }
    }
    final resolvedBirthTime = await _resolveBirthTime(ref, type);

    final imageHint = _imageHint(type, images);

    var loadingCancelled = false;
    unawaited(FortuneAmbientAudio.playOpening());
    showPremiumFortuneLoading(
      context: context,
      title: _loadingTitle(type, images),
      subtitle: _loadingSubtitle(type, images),
      accent: type.accent,
      onCancel: () => loadingCancelled = true,
    );
    var loadingDismissed = false;
    void dismissLoading() {
      if (loadingDismissed || !context.mounted) return;
      loadingDismissed = true;
      unawaited(FortuneAmbientAudio.fadeOutAndStop());
      Navigator.of(context, rootNavigator: true).maybePop();
    }

    FortuneReadingResult? result;
    var usedRemote = false;

    try {
      FortuneCloudImageInput? cloudImages;
      if (images != null && FortuneImageCaptureConfig.requiresCapture(type)) {
        try {
          cloudImages = await _uploadImages(ref, type, images);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
          return null;
        }
      }

      if (loadingCancelled) return null;

      if (authed != null) {
        final accessToken = await ref.read(tokenStorageProvider).readAccess();
        var streamed = false;
        if (accessToken != null && accessToken.trim().isNotEmpty) {
          try {
            final streamedData = await _streamWithGuards(
              ref: ref,
              type: type,
              userInput: userInput,
              yesNoChoice: resolvedYesNo,
              birthDate: resolvedBirth,
              birthTime: resolvedBirthTime,
              images: cloudImages,
              accessToken: accessToken,
              paymentMethod: paymentMethod,
              jetonCost: jetonCost,
              cancelled: () => loadingCancelled,
            );
            if (streamedData != null && streamedData.text.trim().isNotEmpty) {
              streamed = true;
              usedRemote = true;
              result = _service.enrichFromApiText(
                type: type,
                text: streamedData.text,
                recordId: streamedData.fortuneId,
                imageHint: imageHint,
              );
            }
          } catch (_) {
            streamed = false;
          }
        }
        if (loadingCancelled) return null;
        if (!streamed) {
          final remote = await ref.read(fortuneRemoteProvider).readFortune(
                type: type,
                userInput: userInput,
                yesNoChoice: resolvedYesNo,
                birthDate: resolvedBirth,
                birthTime: resolvedBirthTime,
                images: cloudImages,
                paymentMethod: paymentMethod,
                jetonCost: jetonCost,
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
      if (loadingCancelled) return null;
      final msg = ApiException.userMessage(e);
      final lower = msg.toLowerCase();
      final needsPurchase =
          lower.contains('kredi') ||
          lower.contains('jeton') ||
          lower.contains('credit') ||
          lower.contains('bakiye') ||
          (e is ApiException && e.statusCode == 402);
      if (needsPurchase) {
        if (context.mounted) {
          await _showPurchasePrompt(context, msg);
        }
        return null;
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
    } finally {
      dismissLoading();
    }

    if (loadingCancelled || result == null) return null;

    var finalResult = result;
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

      // Backend fal sonucunu sosyal akışa otomatik ekler; Flutter yalnızca
      // gerçek zamanlı senkronize eder (POST oluşturmaz).
      unawaited(
        ref
            .read(fortuneShareHandlerProvider)
            .autoShareIfEnabled(finalResult)
            .catchError((_) => false),
      );
    }

    if (!context.mounted) return null;
    if (stayOnPage) return finalResult;
    if (replaceCurrentRoute) {
      context.pushReplacement('/fortune/${type.slug}/result', extra: finalResult);
    } else {
      context.push('/fortune/${type.slug}/result', extra: finalResult);
    }
    return finalResult;
  }

  static Future<DateTime?> _resolveBirthDate(
    WidgetRef ref,
    FortuneTypeEntity type,
  ) async {
    final needsBirth = type.kind == FortuneSessionKind.zodiacWheel ||
        type.kind == FortuneSessionKind.numberInput ||
        type.slug == 'yildiz-haritasi' ||
        type.slug == 'burc-yorumu' ||
        type.slug == 'numeroloji';
    if (!needsBirth) return null;
    try {
      final profile = await ref.read(fortuneBirthProfileProvider.future);
      return profile?.birthDate;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _resolveBirthTime(WidgetRef ref, FortuneTypeEntity type) async {
    final needsBirth = type.kind == FortuneSessionKind.zodiacWheel ||
        type.kind == FortuneSessionKind.numberInput ||
        type.slug == 'yildiz-haritasi' ||
        type.slug == 'burc-yorumu' ||
        type.slug == 'numeroloji';
    if (!needsBirth) return null;
    try {
      final profile = await ref.read(fortuneBirthProfileProvider.future);
      return profile?.birthTimeIso;
    } catch (_) {
      return null;
    }
  }

  static Future<({String text, String? fortuneId})?> _streamWithGuards({
    required WidgetRef ref,
    required FortuneTypeEntity type,
    String? userInput,
    bool? yesNoChoice,
    DateTime? birthDate,
    String? birthTime,
    FortuneCloudImageInput? images,
    required String accessToken,
    String? paymentMethod,
    int? jetonCost,
    required bool Function() cancelled,
  }) async {
    final session = ref.read(fortuneRemoteProvider).openStreamSession(
          type: type,
          userInput: userInput,
          yesNoChoice: yesNoChoice,
          birthDate: birthDate,
          birthTime: birthTime,
          images: images,
          accessToken: accessToken,
          paymentMethod: paymentMethod,
          jetonCost: jetonCost,
        );

    final stream = session.stream.map(
      (chunk) => FortuneStreamUpdate(
        text: chunk.content,
        fortuneId: chunk.fortuneId,
        done: chunk.done,
      ),
    );

    var text = '';
    String? fortuneId;
    final done = Completer<void>();
    Timer? idleTimer;
    StreamSubscription<FortuneStreamUpdate>? sub;

    void finish() {
      idleTimer?.cancel();
      if (!done.isCompleted) done.complete();
    }

    sub = stream.listen(
      (update) {
        if (cancelled()) {
          session.cancel('user_cancelled');
          finish();
          return;
        }
        text = update.text;
        fortuneId = update.fortuneId ?? fortuneId;
        idleTimer?.cancel();
        idleTimer = Timer(_streamIdleGap, finish);
        if (update.done) finish();
      },
      onDone: finish,
      onError: (_) => finish(),
      cancelOnError: true,
    );

    Timer(_streamMaxWait, () {
      session.cancel('timeout');
      finish();
    });
    await done.future;
    await sub.cancel();
    idleTimer?.cancel();
    if (!cancelled()) {
      session.cancel('done');
    }

    if (cancelled() || text.trim().isEmpty) return null;
    return (text: text, fortuneId: fortuneId);
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
