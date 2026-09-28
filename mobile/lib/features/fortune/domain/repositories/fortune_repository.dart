import '../../../../core/pagination/paged_result.dart';
import '../entities/fortune_image_input.dart';
import '../entities/fortune_type_entity.dart';
import '../entities/user_fortune_entity.dart';

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
    String? paymentMethod,
    int? jetonCost,
  });

  Future<FortuneReadingResult> readFortune({
    required FortuneTypeEntity type,
    String? userInput,
    bool? yesNoChoice,
    DateTime? birthDate,
    FortuneCloudImageInput? images,
    String? paymentMethod,
    int? jetonCost,
  });

  Future<PagedResult<UserFortuneEntity>> history({
    int page = 1,
    int limit = 20,
  });

  Future<UserFortuneEntity> detail(String fortuneId);
}
