import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;
  String? _cachedToken;

  ApiClient(this._tokenStorage);

  void init() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  void setToken(String? token) {
    _cachedToken = token;
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _cachedToken ?? await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await dio.post(
            '/api/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );
          final newAccess = response.data['accessToken'] as String;
          final newRefresh = response.data['refreshToken'] as String;
          await _tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          _cachedToken = newAccess;
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retried = await dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        } catch (_) {
          _cachedToken = null;
          await _tokenStorage.clear();
        }
      }
    }
    handler.next(err);
  }
}
