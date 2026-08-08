import 'package:dio/dio.dart';

/// API isteklerinde beklenmeyen HTML cevaplarını JSON gibi parse etmeyi engeller.
class JsonContentTypeGuardInterceptor extends Interceptor {
  static bool isUnexpectedHtmlApiResponse(Response<dynamic> response) {
    final path = response.requestOptions.path.trim();
    final isApiPath = path.startsWith('/api/') || path.startsWith('api/');
    if (!isApiPath) return false;

    final responseType = response.requestOptions.responseType;
    if (responseType == ResponseType.bytes || responseType == ResponseType.stream) {
      return false;
    }

    final contentType =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    final data = response.data;
    final htmlContentType = contentType.contains('text/html');
    final htmlBody = data is String &&
        (data.trimLeft().startsWith('<!DOCTYPE') ||
            data.trimLeft().startsWith('<html'));
    return htmlContentType || htmlBody;
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!isUnexpectedHtmlApiResponse(response)) {
      return handler.next(response);
    }
    handler.reject(
      DioException.badResponse(
        statusCode: response.statusCode ?? 200,
        requestOptions: response.requestOptions,
        response: response,
      ),
    );
  }
}
