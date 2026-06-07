import '../../../../core/pagination/paged_result.dart';
import '../entities/user_fortune_entity.dart';

class SaveFortuneInput {
  const SaveFortuneInput({
    required this.type,
    this.slug,
    this.question,
    this.answer,
    this.summary,
    this.detail,
    this.luckyNumber,
    this.luckyColor,
  });

  final String type;
  final String? slug;
  final String? question;
  final String? answer;
  final String? summary;
  final String? detail;
  final int? luckyNumber;
  final String? luckyColor;
}

abstract class FortuneRepository {
  Future<PagedResult<UserFortuneEntity>> history({int page = 1, int limit = 20});

  Future<UserFortuneEntity> detail(String fortuneId);

  Future<UserFortuneEntity> save(SaveFortuneInput input);
}
