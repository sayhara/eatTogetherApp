import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/gathering/screens/gathering_detail_screen.dart';
import '../../features/gathering/screens/gathering_create_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/review/screens/review_screen.dart';
import '../../features/mypage/screens/mypage_screen.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authProvider, (prev, next) {
      debugPrint('[ROUTER] authProvider changed: ${prev.runtimeType}(${prev?.value?.id}) => ${next.runtimeType}(${next.value?.id})');
      notifyListeners();
    });
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState is AsyncLoading;
      final isLoggedIn = authState.value != null;
      final isLoginPath = state.matchedLocation == '/login';

      debugPrint('[ROUTER] redirect: loc=${state.matchedLocation}, loading=$isLoading, loggedIn=$isLoggedIn');

      if (isLoading) return null;
      if (!isLoggedIn && !isLoginPath) return '/login';
      if (isLoggedIn && isLoginPath) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, _) => const MainScreen(),
      ),
      GoRoute(
        path: '/gathering/create',
        builder: (context, _) => const GatheringCreateScreen(),
      ),
      GoRoute(
        path: '/gathering/:id',
        builder: (context, state) => GatheringDetailScreen(
          gatheringId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/gathering/:id/chat',
        builder: (context, state) => ChatScreen(
          gatheringId: int.parse(state.pathParameters['id']!),
          gatheringTitle: state.uri.queryParameters['title'] ?? '',
        ),
      ),
      GoRoute(
        path: '/gathering/:id/review',
        builder: (context, state) => ReviewScreen(
          gatheringId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/mypage',
        builder: (context, _) => const MyPageScreen(),
      ),
    ],
  );
});
