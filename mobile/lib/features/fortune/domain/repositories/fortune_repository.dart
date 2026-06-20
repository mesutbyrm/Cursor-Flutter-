import '../../../../core/pagination/paged_result.dart';
import '../entities/fortune_image_input.dart';
import '../entities/fortune_type_entity.dart';
import '../entities/user_fortune_entity.dart';

class SaveFortuneInput {
  const SaveFortuneInput({
    required this.type,
    this.slug,
    this.question,
    this.answer,
    this.summary,
    this.detail,
    this.imageUrl,
    this.fortuneText,
    this.visualAnalysis,
    this.luckyNumber,
    this.luckyColor,
  });

  final String type;
  final String? slug;
  final String? question;
  final String? answer;
  final String? summary;
  final String? detail;
  final String? imageUrl;
  final String? fortuneText;
  final String? visualAnalysis;
  final int? luckyNumber;
  final String? luckyColor;
}

/// SSE fal akışı parçası.
class FortuneStreamUpdate {
  const FortuneStreamUpdate({
    required this.text,
    this.fortuneId,
    this.done = false,
  });

  final String text;
  final String? fortuneId;
  final bool done;
}

abstract class FortuneRepository {
  Stream<FortuneStreamUpdate> streamFortune({
    required FortuneTypeEntity type,
    String? userInput,
    bool? yesNoChoice,
    DateTime? birthDate,
    FortuneCloudImageInput? images,
    required String accessToken,
  });

  Future<FortuneReadingResult> readFortune({
    required FortuneTypeEntity type,
    String? userInput,
    bool? yesNoChoice,
    DateTime? birthDate,
    FortuneCloudImageInput? images,
  });

  Future<PagedResult<UserFortuneEntity>> history({
    int page = 1,
    int limit = 20,
  });

  Future<UserFortuneEntity> detail(String fortuneId);

  Future<UserFortuneEntity> save(SaveFortuneInput input);
}
