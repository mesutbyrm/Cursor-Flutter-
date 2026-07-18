import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/site_page_entity.dart';

class SitePageRemoteDataSource {
  SitePageRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SitePageEntity?> fetch(String slug) async {
    final key = slug.trim();
    if (key.isEmpty) return null;
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.sitePage(key));
    final map = asJsonMap(res.data);
    if (map == null) return null;
    final page = asJsonMap(map['page']) ?? map;
    final title = pick(page, ['title', 'titleTr', 'name'])?.toString().trim() ?? '';
    final content = pick(page, ['content', 'contentTr', 'html', 'body'])
            ?.toString()
            .trim() ??
        '';
    if (title.isEmpty || content.isEmpty) {
      return null;
    }
    return SitePageEntity(
      slug: pick(page, ['slug'])?.toString() ?? key,
      title: title,
      html: content,
    );
  }
}
