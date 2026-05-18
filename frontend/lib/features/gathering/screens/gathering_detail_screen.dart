import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/gathering_model.dart';
import '../providers/gathering_provider.dart';

class GatheringDetailScreen extends ConsumerStatefulWidget {
  final int gatheringId;
  const GatheringDetailScreen({super.key, required this.gatheringId});

  @override
  ConsumerState<GatheringDetailScreen> createState() => _GatheringDetailScreenState();
}

class _GatheringDetailScreenState extends ConsumerState<GatheringDetailScreen> {
  static const _categoryColor = {
    'KOREAN': Color(0xFFFF8C42),
    'CHINESE': Color(0xFFE53935),
    'JAPANESE': Color(0xFFEC407A),
    'WESTERN': Color(0xFF5C6BC0),
    'FAST_FOOD': Color(0xFFFFB300),
    'CAFE': Color(0xFF8D6E63),
    'OTHER': Color(0xFF26A69A),
  };

  static const _categoryEmoji = {
    'KOREAN': '🍲',
    'CHINESE': '🥟',
    'JAPANESE': '🍱',
    'WESTERN': '🍝',
    'FAST_FOOD': '🍔',
    'CAFE': '☕',
    'OTHER': '🍽️',
  };

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _formatDate(DateTime dt) {
    final w = _weekdays[dt.weekday - 1];
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 ($w)';
  }

  String _formatTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(gatheringDetailProvider(widget.gatheringId));
    final user = ref.watch(authProvider).value;
    final isLoading = ref.watch(gatheringActionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF03C75A))),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (gathering) {
          final isHost = user?.id == gathering.hostId;
          final color = _categoryColor[gathering.category] ?? const Color(0xFF26A69A);
          final emoji = _categoryEmoji[gathering.category] ?? '🍽️';
          final isOpen = gathering.status == 'OPEN';
          final isClosed = gathering.status == 'CLOSED';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Hero image + AppBar
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0.5,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    title: const Text(
                      '모임 정보',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    centerTitle: true,
                    actions: [
                      if (isHost)
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showOptions(context, gathering, ref),
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 90)),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  gathering.title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOpen ? const Color(0xFFFFD600) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOpen ? '모집중' : (isClosed ? '완료' : '마감'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),

                          // Description
                          if (gathering.description != null && gathering.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              gathering.description!,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                            ),
                          ],

                          // 참여 인원
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '${gathering.currentParticipants}/${gathering.maxParticipants}명 참여 중',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '주최: ${gathering.hostNickname}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // 모임 일시
                          const Text('모임 일시', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.calendar_month_outlined,
                            iconColor: const Color(0xFF5C6BC0),
                            text: _formatDate(gathering.mealTime),
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF5C6BC0),
                            text: _formatTime(gathering.mealTime),
                          ),

                          const SizedBox(height: 28),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // 모임 장소
                          const Text('모임 장소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.place_outlined,
                            iconColor: Colors.red,
                            text: gathering.restaurantName,
                          ),
                          if (gathering.address != null && gathering.address!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Text(
                                gathering.address!,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Map thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 160,
                              child: KakaoMap(
                                center: LatLng(gathering.latitude, gathering.longitude),
                                markers: [
                                  Marker(
                                    markerId: gathering.id.toString(),
                                    latLng: LatLng(gathering.latitude, gathering.longitude),
                                  ),
                                ],
                                onMapCreated: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom action bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 채팅 버튼
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/gathering/${widget.gatheringId}/chat?title=${Uri.encodeComponent(gathering.title)}',
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('채팅'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF03C75A),
                            side: const BorderSide(color: Color(0xFF03C75A)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 주 액션 버튼
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          gathering: gathering,
                          isHost: isHost,
                          isLoading: isLoading,
                          gatheringId: widget.gatheringId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOptions(BuildContext context, GatheringModel gathering, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF03C75A)),
              title: const Text('모임 완료하기'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(gatheringActionProvider.notifier).complete(widget.gatheringId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모임이 완료되었습니다')));
                  context.pop();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final GatheringModel gathering;
  final bool isHost;
  final bool isLoading;
  final int gatheringId;

  const _ActionButton({
    required this.gathering,
    required this.isHost,
    required this.isLoading,
    required this.gatheringId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gathering.status == 'CLOSED') {
      return ElevatedButton.icon(
        onPressed: () => context.push('/gathering/$gatheringId/review'),
        icon: const Icon(Icons.star_outline, size: 18),
        label: const Text('리뷰 작성'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (isHost) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('내가 만든 모임', style: TextStyle(fontSize: 15)),
      );
    }

    return ElevatedButton(
      onPressed: isLoading || gathering.isFull || !gathering.isOpen
          ? null
          : () async {
              await ref.read(gatheringActionProvider.notifier).join(gatheringId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('참여 신청이 완료되었습니다!')),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: gathering.isFull ? Colors.grey : const Color(0xFF03C75A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isLoading ? '처리 중...' : (gathering.isFull ? '인원 마감' : '참여하기'),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _DetailRow({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
      ],
    );
  }
}
