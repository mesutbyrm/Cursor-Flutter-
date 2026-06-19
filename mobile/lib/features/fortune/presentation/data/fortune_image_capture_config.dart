import '../../domain/entities/fortune_image_input.dart';
import '../../domain/entities/fortune_type_entity.dart';

export '../../domain/entities/fortune_image_input.dart';

/// Görsel yükleme gerektiren fal türleri.
abstract final class FortuneImageCaptureConfig {
  static bool requiresCapture(FortuneTypeEntity type) =>
      type.kind == FortuneSessionKind.coffeeCup ||
      type.kind == FortuneSessionKind.palmScan;

  static bool isCoffee(FortuneTypeEntity type) =>
      type.kind == FortuneSessionKind.coffeeCup;

  static bool isPalm(FortuneTypeEntity type) =>
      type.kind == FortuneSessionKind.palmScan;

  static String apiSlugFor(FortuneTypeEntity type) {
    if (isCoffee(type)) return 'kahve-fali-image';
    return 'el-fali';
  }
}

extension FortuneLocalImageInputValidation on FortuneLocalImageInput {
  bool isValidFor(FortuneTypeEntity type) {
    if (FortuneImageCaptureConfig.isCoffee(type)) {
      return cupPath != null && cupPath!.trim().isNotEmpty;
    }
    if (FortuneImageCaptureConfig.isPalm(type)) {
      return palmPath != null && palmPath!.trim().isNotEmpty;
    }
    return true;
  }
}
