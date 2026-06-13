import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _ProfileHeader(user: user),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.restaurant,
                  label: '내 모임 내역',
                  onTap: () => _showMyGatherings(context, ref),
                ),
                _MenuTile(
                  icon: Icons.block,
                  label: '차단한 사용자',
                  onTap: () => _showBlockedUsers(context, ref),
                ),
                _MenuTile(
                  icon: Icons.manage_accounts,
                  label: '계정 관리',
                  onTap: () => context.push('/settings'),
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.logout,
                  label: '로그아웃',
                  textColor: Colors.red,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }

  void _showMyGatherings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MyGatheringsSheet(ref: ref),
    );
  }

  void _showBlockedUsers(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BlockedUsersSheet(ref: ref),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF03C75A),
            backgroundImage: user.profileImageUrl != null
                ? CachedNetworkImageProvider(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.nickname.substring(0, 1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nickname,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (user.email != null)
                Text(user.email!,
                    style: const TextStyle(color: Colors.grey)),
              Text(
                user.provider.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF03C75A), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF03C75A)),
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _MyGatheringsSheet extends StatefulWidget {
  final WidgetRef ref;
  const _MyGatheringsSheet({required this.ref});

  @override
  State<_MyGatheringsSheet> createState() => _MyGatheringsSheetState();
}

class _MyGatheringsSheetState extends State<_MyGatheringsSheet> {
  List<Map<String, dynamic>> _gatherings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = widget.ref.read(apiClientProvider);
      final hostedRes = await client.dio.get('/api/gatherings/my/hosted');
      final joinedRes = await client.dio.get('/api/gatherings/my/joined');
      final hosted = ((hostedRes.data as Map<String, dynamic>)['data'] as List<dynamic>)
          .map((e) => {...e as Map<String, dynamic>, 'isHosted': true}).toList();
      final joined = ((joinedRes.data as Map<String, dynamic>)['data'] as List<dynamic>)
          .map((e) => {...e as Map<String, dynamic>, 'isHosted': false}).toList();
      final seen = <int>{};
      setState(() {
        _gatherings = [...hosted, ...joined]
            .where((g) => seen.add(g['id'] as int))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('내 모임 내역',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gatherings.isEmpty
                    ? const Center(child: Text('참여한 모임이 없습니다'))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: _gatherings.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final g = _gatherings[i];
                          final isHosted = g['isHosted'] as bool? ?? false;
                          return ListTile(
                            title: Text(g['title'] as String? ?? ''),
                            subtitle: Text(g['restaurantName'] as String? ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  g['status'] as String? ?? '',
                                  style: TextStyle(
                                    color: g['status'] == 'OPEN'
                                        ? const Color(0xFF03C75A)
                                        : Colors.grey,
                                  ),
                                ),
                                if (isHosted) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Color(0xFF03C75A)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/gathering/${g['id']}/edit');
                                    },
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/gathering/${g['id']}');
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUsersSheet extends StatefulWidget {
  final WidgetRef ref;
  const _BlockedUsersSheet({required this.ref});

  @override
  State<_BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends State<_BlockedUsersSheet> {
  List<Map<String, dynamic>> _blocked = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = widget.ref.read(apiClientProvider);
      final res = await client.dio.get('/api/users/me/blocks');
      setState(() {
        _blocked = ((res.data as Map<String, dynamic>)['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblock(int userId) async {
    try {
      await widget.ref.read(apiClientProvider).dio.delete('/api/users/$userId/block');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('차단한 사용자',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blocked.isEmpty
                    ? const Center(child: Text('차단한 사용자가 없습니다'))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: _blocked.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = _blocked[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Text(
                                (u['nickname'] as String? ?? '?')
                                    .substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(u['nickname'] as String? ?? ''),
                            trailing: TextButton(
                              onPressed: () =>
                                  _unblock(u['blockedUserId'] as int),
                              child: const Text('차단 해제',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
