import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/gathering_provider.dart';

class GatheringDetailScreen extends ConsumerWidget {
  final int gatheringId;

  const GatheringDetailScreen({super.key, required this.gatheringId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(gatheringDetailProvider(gatheringId));
    final user = ref.watch(authProvider).value;
    final isLoading = ref.watch(gatheringActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 상세'),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (gathering) {
          final isHost = user?.id == gathering.hostId;
          final fmt = DateFormat('MM월 dd일 HH:mm');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gathering.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusChip(gathering.status),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(Icons.restaurant, gathering.restaurantName),
                if (gathering.address != null)
                  _InfoRow(Icons.location_on, gathering.address!),
                _InfoRow(Icons.access_time, fmt.format(gathering.mealTime)),
                _InfoRow(
                  Icons.people,
                  '${gathering.currentParticipants}/${gathering.maxParticipants}명 참여 중',
                ),
                if (gathering.category != null)
                  _InfoRow(Icons.category, gathering.category!),
                if (gathering.description != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '모임 소개',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(gathering.description!),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      '주최자',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(gathering.hostNickname),
                  ],
                ),
                const SizedBox(height: 32),
                if (gathering.status == 'OPEN') ...[
                  if (isHost) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(gatheringActionProvider.notifier)
                                    .complete(gatheringId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('모임이 완료되었습니다')),
                                  );
                                  context.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03C75A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('모임 완료하기', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading || gathering.isFull
                                ? null
                                : () async {
                                    await ref
                                        .read(gatheringActionProvider.notifier)
                                        .join(gatheringId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('참여 신청이 완료되었습니다')));
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF03C75A),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              gathering.isFull ? '인원 마감' : '참여하기',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (gathering.status == 'CLOSED') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/gathering/$gatheringId/review',
                      ),
                      icon: const Icon(Icons.star),
                      label: const Text('리뷰 작성하기', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/gathering/$gatheringId/chat?title=${Uri.encodeComponent(gathering.title)}',
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('채팅방 입장', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF03C75A),
                      side: const BorderSide(color: Color(0xFF03C75A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'OPEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF03C75A) : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? '모집 중' : '완료',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF03C75A)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
