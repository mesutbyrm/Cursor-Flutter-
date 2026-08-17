import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/legal_document.dart';
import '../domain/site_page_entity.dart';

class SitePageRemoteDataSource {
  SitePageRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SitePageEntity?> fetch(String slug) async {
    final key = slug.trim();
    if (key.isEmpty) return null;
    final doc = legalDocumentForSlug(key);
    final path = doc?.apiPath ?? ApiEndpoints.sitePage(key);
    try {
      final res = await _dio.safeGet<dynamic>(path);
      return _parseResponse(res.data, fallbackSlug: key);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && doc?.apiPath == null) {
        return null;
      }
      rethrow;
    }
  }

  SitePageEntity? _parseResponse(dynamic data, {required String fallbackSlug}) {
    if (data == null) return null;
    final map = asJsonMap(data);
    if (map.isEmpty) return null;
    final source = map['page'] is Map ? asJsonMap(map['page']) : map;
    final title = pick(source, ['title', 'titleTr', 'name'])?.toString().trim() ?? '';
    final content = pick(source, ['content', 'contentTr', 'html', 'body'])
            ?.toString()
            .trim() ??
        '';
    if (title.isEmpty || content.isEmpty) {
      return null;
    }
    return SitePageEntity(
      slug: pick(source, ['slug'])?.toString() ?? fallbackSlug,
      title: title,
      html: content,
    );
  }
}
