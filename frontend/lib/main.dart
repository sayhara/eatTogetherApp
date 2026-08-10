import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  await FlutterNaverMap().init(clientId: 'lj90ug6jml');
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {}
  runApp(const ProviderScope(child: EatTogetherApp()));
}

class EatTogetherApp extends ConsumerStatefulWidget {
  const EatTogetherApp({super.key});

  @override
  ConsumerState<EatTogetherApp> createState() => _EatTogetherAppState();
}

class _EatTogetherAppState extends ConsumerState<EatTogetherApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initFcmToken();
  }

  String? _lastHandledToken;

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[DEEPLINK] uriLinkStream: $uri');
      _handleDeepLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      debugPrint('[DEEPLINK] getInitialLink: $uri');
      if (uri != null) _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('[DEEPLINK] handling: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}');
    if (uri.scheme == 'eattogether' &&
        uri.host == 'oauth2' &&
        uri.path == '/callback') {
      if (uri.queryParameters['linkRequired'] == 'true') {
        final linkToken = uri.queryParameters['linkToken'];
        final email = uri.queryParameters['email'] ?? '';
        debugPrint('[DEEPLINK] linkRequired, linkToken=${linkToken == null ? "null" : "present"}');
        if (linkToken != null && mounted) {
          ref.read(routerProvider).go(
              '/link-account?linkToken=$linkToken&email=${Uri.encodeComponent(email)}');
        }
        return;
      }
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];
      debugPrint('[DEEPLINK] accessToken=${accessToken == null ? "null" : "present"}, refreshToken=${refreshToken == null ? "null" : "present"}');
      if (accessToken == null || refreshToken == null) return;
      if (accessToken == _lastHandledToken) {
        debugPrint('[DEEPLINK] duplicate token, skipping');
        return;
      }
      _lastHandledToken = accessToken;
      debugPrint('[DEEPLINK] calling loginWithTokens');
      await ref.read(authProvider.notifier).loginWithTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
      debugPrint('[DEEPLINK] loginWithTokens done, navigating to /');
      if (mounted) {
        ref.read(routerProvider).go('/');
      }
    }
  }

  Future<void> _initFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final client = ref.read(apiClientProvider);
        await client.dio.post('/api/fcm/token', data: {
          'token': token,
          'deviceId': 'flutter-device',
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '잇투게더',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF03C75A)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF03C75A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      routerConfig: router,
    );
  }
}
