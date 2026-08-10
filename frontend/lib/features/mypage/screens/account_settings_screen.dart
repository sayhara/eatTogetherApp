import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCheckingNickname = false;
  bool? _isNicknameAvailable;
  bool _isSavingNickname = false;
  bool _isSavingNotification = false;
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkNickname(String nickname) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    if (nickname == user.nickname) {
      setState(() => _isNicknameAvailable = null);
      return;
    }
    if (nickname.length < 2 || nickname.length > 12) {
      setState(() => _isNicknameAvailable = null);
      return;
    }
    setState(() {
      _isCheckingNickname = true;
      _isNicknameAvailable = null;
    });
    try {
      final res = await ref.read(apiClientProvider).dio.get(
        '/api/users/nickname/check',
        queryParameters: {'nickname': nickname},
      );
      final available = (res.data as Map<String, dynamic>)['data'] as bool;
      if (mounted) setState(() => _isNicknameAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _isNicknameAvailable = null);
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    final user = ref.read(authProvider).value;
    if (user == null) return;
    if (nickname == user.nickname) return;
    if (_isNicknameAvailable != true) return;

    setState(() => _isSavingNickname = true);
    try {
      await ref.read(apiClientProvider).dio.patch(
        '/api/users/me/nickname',
        data: {'nickname': nickname},
      );
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임이 변경됐습니다')),
        );
        setState(() => _isNicknameAvailable = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 변경에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNickname = false);
    }
  }

  Future<void> _toggleNotification(bool enabled) async {
    setState(() => _isSavingNotification = true);
    try {
      await ref.read(apiClientProvider).dio.patch(
        '/api/users/me/notification',
        data: {'enabled': enabled},
      );
      await ref.read(authProvider.notifier).refreshUser();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 설정 변경에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotification = false);
    }
  }

  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정을 탈퇴하시겠습니까?'),
        content: const Text('탈퇴 시 프로필 정보가 삭제되며 되돌릴 수 없습니다.\n정말로 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _withdraw();
  }

  Future<void> _withdraw() async {
    setState(() => _isWithdrawing = true);
    try {
      await ref.read(apiClientProvider).dio.delete('/api/users/me');
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('탈퇴 처리에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final typed = _nicknameController.text.trim();
    final isNicknameChanged = typed.isNotEmpty && typed != user.nickname;

    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 관리'),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 닉네임 섹션
            const Text(
              '닉네임',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nicknameController,
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: user.nickname,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: _isCheckingNickname
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _isNicknameAvailable == true
                              ? const Icon(Icons.check_circle, color: Color(0xFF03C75A))
                              : _isNicknameAvailable == false
                                  ? const Icon(Icons.cancel, color: Colors.red)
                                  : null,
                    ),
                    onChanged: (v) {
                      setState(() => _isNicknameAvailable = null);
                      if (v.trim().length >= 2) _checkNickname(v.trim());
                    },
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isNotEmpty && s.length < 2) return '2자 이상 입력해주세요';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isNicknameChanged && (_isNicknameAvailable == true) && !_isSavingNickname
                        ? _saveNickname
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03C75A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSavingNickname
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('변경'),
                  ),
                ),
              ],
            ),
            if (_isNicknameAvailable == false)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text('이미 사용 중인 닉네임입니다', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if (_isNicknameAvailable == true)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text('사용 가능한 닉네임입니다', style: TextStyle(color: Color(0xFF03C75A), fontSize: 12)),
              ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 알림 섹션
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('푸시 알림', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('모임 참여 신청, 채팅 등 알림을 받습니다', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                _isSavingNotification
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: user.notificationEnabled,
                        activeThumbColor: const Color(0xFF03C75A),
                        onChanged: _toggleNotification,
                      ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 계정 정보
            const Text(
              '계정 정보',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: '로그인 방식', value: user.provider.toUpperCase()),
            if (user.email != null) _InfoRow(label: '이메일', value: user.email!),
            const SizedBox(height: 8),
            const Text(
              '비밀번호는 소셜 계정(카카오/구글/네이버)에서 관리됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: _isWithdrawing ? null : _confirmWithdraw,
                child: _isWithdrawing
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(
                        '계정 탈퇴',
                        style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
