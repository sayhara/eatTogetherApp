import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;
  String? _cachedToken;
  Future<String?>? _refreshFuture;

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
    // reissue 요청 자체가 401이면(리프레시 토큰도 무효) 재발급을 다시 시도하지 않는다.
    // 그렇지 않으면 _doRefresh()가 이 인터셉터를 재귀 호출해 자기 자신의 완료를
    // 기다리는 데드락에 빠진다.
    final isReissueRequest = err.requestOptions.path == '/api/auth/reissue';
    if (err.response?.statusCode == 401 && !isReissueRequest) {
      // Mutex: if refresh is already in progress, wait for it
      if (_refreshFuture != null) {
        await _refreshFuture;
      } else {
        _refreshFuture = _doRefresh();
        await _refreshFuture;
        _refreshFuture = null;
      }

      final newToken = _cachedToken;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retried = await dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        } catch (retryErr) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await dio.post(
        '/api/auth/reissue',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final tokenData = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final newAccess = tokenData['accessToken'] as String;
      final newRefresh = tokenData['refreshToken'] as String;
      await _tokenStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      _cachedToken = newAccess;
      return newAccess;
    } catch (_) {
      _cachedToken = null;
      await _tokenStorage.clear();
      return null;
    }
  }
}
