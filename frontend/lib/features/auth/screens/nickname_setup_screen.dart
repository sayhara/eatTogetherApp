import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class NicknameSetupScreen extends ConsumerStatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  ConsumerState<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends ConsumerState<NicknameSetupScreen> {
  final _controller = TextEditingController();
  bool _isChecking = false;
  bool? _isAvailable;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNickname(String nickname) async {
    if (nickname.length < 2 || nickname.length > 12) {
      setState(() => _isAvailable = null);
      return;
    }
    setState(() {
      _isChecking = true;
      _isAvailable = null;
    });
    try {
      final res = await ref.read(apiClientProvider).dio.get(
        '/api/users/nickname/check',
        queryParameters: {'nickname': nickname},
      );
      final available = (res.data as Map<String, dynamic>)['data'] as bool;
      if (mounted) setState(() => _isAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _isAvailable = null);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _save() async {
    final nickname = _controller.text.trim();
    if (_isAvailable != true || nickname.length < 2) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(apiClientProvider).dio.patch(
        '/api/users/me/nickname',
        data: {'nickname': nickname},
      );
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 설정에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _isAvailable == true && !_isSaving && _controller.text.trim().length >= 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '닉네임을 설정해주세요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '다른 사용자에게 표시될 이름입니다.\n2~12자, 나중에 변경할 수 있어요.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                maxLength: 12,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '닉네임 입력 (2~12자)',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF03C75A), width: 2),
                  ),
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : _isAvailable == true
                          ? const Icon(Icons.check_circle, color: Color(0xFF03C75A))
                          : _isAvailable == false
                              ? const Icon(Icons.cancel, color: Colors.red)
                              : null,
                ),
                onChanged: (v) {
                  setState(() => _isAvailable = null);
                  if (v.trim().length >= 2) _checkNickname(v.trim());
                },
              ),
              const SizedBox(height: 8),
              if (_isAvailable == false)
                const Text('이미 사용 중인 닉네임입니다', style: TextStyle(color: Colors.red, fontSize: 12)),
              if (_isAvailable == true)
                const Text('사용 가능한 닉네임입니다', style: TextStyle(color: Color(0xFF03C75A), fontSize: 12)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03C75A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
