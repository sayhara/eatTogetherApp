import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void _launchOAuth(BuildContext context, String provider) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/oauth2/authorization/$provider',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('브라우저를 열 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 80, color: Color(0xFF03C75A)),
              const SizedBox(height: 16),
              const Text(
                '잇투게더',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF03C75A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '근처의 사람들과 함께 밥을 먹어요',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              _SocialLoginButton(
                label: '카카오로 시작하기',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                icon: Icons.chat_bubble,
                onTap: () => _launchOAuth(context, 'kakao'),
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                label: 'Google로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                icon: Icons.g_mobiledata,
                borderColor: Colors.grey.shade300,
                onTap: () => _launchOAuth(context, 'google'),
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                label: '네이버로 시작하기',
                color: const Color(0xFF03C75A),
                textColor: Colors.white,
                icon: Icons.nature,
                onTap: () => _launchOAuth(context, 'naver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final Color? borderColor;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
