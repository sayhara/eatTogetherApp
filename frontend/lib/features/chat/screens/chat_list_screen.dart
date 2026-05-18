import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/gathering_model.dart';

final _myGatheringsProvider = FutureProvider<List<GatheringModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  // 내가 호스트이거나 승인된 참가자인 모든 모임
  final hostedFut = client.dio.get('/api/gatherings/my/hosted');
  final joinedFut = client.dio.get('/api/gatherings/my/joined');
  final results = await Future.wait([hostedFut, joinedFut]);

  final hosted = ((results[0].data as Map<String, dynamic>)['data'] as List<dynamic>)
      .map((e) => GatheringModel.fromJson(e as Map<String, dynamic>))
      .toList();
  final joined = ((results[1].data as Map<String, dynamic>)['data'] as List<dynamic>)
      .map((e) => GatheringModel.fromJson(e as Map<String, dynamic>))
      .toList();

  // 중복 제거 (호스트는 hosted에도, joined에도 있을 수 있음)
  final seen = <int>{};
  final merged = <GatheringModel>[];
  for (final g in [...hosted, ...joined]) {
    if (seen.add(g.id)) merged.add(g);
  }
  merged.sort((a, b) => a.mealTime.compareTo(b.mealTime));
  return merged;
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatheringsAsync = ref.watch(_myGatheringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD600), Color(0xFFFFC107)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '채팅 💬\n내 모임 대화방',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    gatheringsAsync.when(
                      data: (list) => Text(
                        '${list.length}개의 채팅방',
                        style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: gatheringsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF03C75A))),
              error: (e, st) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('불러오기 실패: $e', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(_myGatheringsProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
              data: (gatherings) {
                if (gatherings.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  color: const Color(0xFF03C75A),
                  onRefresh: () async => ref.invalidate(_myGatheringsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: gatherings.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ChatRoomCard(gathering: gatherings[i]),
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

class _ChatRoomCard extends ConsumerWidget {
  final GatheringModel gathering;
  const _ChatRoomCard({required this.gathering});

  static const _categoryEmoji = {
    'KOREAN': '🍲',
    'CHINESE': '🥟',
    'JAPANESE': '🍱',
    'WESTERN': '🍝',
    'FAST_FOOD': '🍔',
    'CAFE': '☕',
    'OTHER': '🍽️',
  };

  static const _categoryColor = {
    'KOREAN': Color(0xFFFF8C42),
    'CHINESE': Color(0xFFE53935),
    'JAPANESE': Color(0xFFEC407A),
    'WESTERN': Color(0xFF5C6BC0),
    'FAST_FOOD': Color(0xFFFFB300),
    'CAFE': Color(0xFF8D6E63),
    'OTHER': Color(0xFF26A69A),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji = _categoryEmoji[gathering.category] ?? '🍽️';
    final color = _categoryColor[gathering.category] ?? const Color(0xFF26A69A);
    final isOpen = gathering.status == 'OPEN';
    final dateFmt = DateFormat('M월 d일 a h:mm', 'ko');

    return GestureDetector(
      onTap: () => context.push(
        '/gathering/${gathering.id}/chat?title=${Uri.encodeComponent(gathering.title)}',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // 이모지 아바타
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gathering.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFFFFD600) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOpen ? '모집중' : (gathering.status == 'COMPLETED' ? '완료' : '마감'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOpen ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          gathering.restaurantName,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        dateFmt.format(gathering.mealTime),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${gathering.currentParticipants}/${gathering.maxParticipants}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('💬', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          const Text('참여 중인 모임이 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('모임에 참여하면 채팅을 이용할 수 있어요', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
