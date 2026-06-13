import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.read(tokenStorageProvider));
  client.init();
  return client;
});

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    debugPrint('[AUTH] build() called - loading user from storage');
    return _loadUser();
  }

  Future<UserModel?> _loadUser([String? tokenOverride]) async {
    final token = tokenOverride ?? await ref.read(tokenStorageProvider).getAccessToken();
    debugPrint('[AUTH] _loadUser: token=${token == null ? "null" : "${token.substring(0, token.length.clamp(0, 20))}..."}');
    if (token == null) return null;
    try {
      final res = await ref.read(apiClientProvider).dio.get('/api/users/me');
      if (res.data is! Map<String, dynamic>) {
        debugPrint('[AUTH] _loadUser: unexpected response type, clearing token');
        await ref.read(tokenStorageProvider).clear();
        return null;
      }
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      debugPrint('[AUTH] _loadUser: /api/users/me => ${res.statusCode}, user=${data['id']}');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[AUTH] _loadUser DioException: ${e.response?.statusCode} ${e.message}');
      if (e.response?.statusCode == 401) {
        await ref.read(tokenStorageProvider).clear();
      }
      return null;
    } catch (e) {
      debugPrint('[AUTH] _loadUser error: $e');
      return null;
    }
  }

  Future<void> loginWithTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    debugPrint('[AUTH] loginWithTokens start');
    state = const AsyncLoading();
    await ref.read(tokenStorageProvider).saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
    debugPrint('[AUTH] loginWithTokens: tokens saved to storage');
    ref.read(apiClientProvider).setToken(accessToken);
    debugPrint('[AUTH] loginWithTokens: token set in apiClient cache');
    state = await AsyncValue.guard(() => _loadUser(accessToken));
    debugPrint('[AUTH] loginWithTokens complete: isData=${state is AsyncData}, value=${state.value?.id}');
  }

  Future<void> logout() async {
    debugPrint('[AUTH] logout called');
    ref.read(apiClientProvider).setToken(null);
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> refreshUser() async {
    state = await AsyncValue.guard(() => _loadUser());
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await ref.read(apiClientProvider).dio.patch('/api/users/me/location', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {}
  }
}
