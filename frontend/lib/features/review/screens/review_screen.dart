import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../auth/providers/auth_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int gatheringId;

  const ReviewScreen({super.key, required this.gatheringId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Map<String, dynamic>> _participants = [];
  final Map<int, double> _ratings = {};
  final Map<int, TextEditingController> _comments = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final client = ref.read(apiClientProvider);
      final me = ref.read(authProvider).value;
      final res = await client.dio
          .get('/api/gatherings/${widget.gatheringId}/participants');
      final list = ((res.data as Map<String, dynamic>)['data'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .where((p) => p['userId'] != me?.id)
          .toList();
      setState(() {
        _participants = list;
        for (final p in list) {
          final uid = p['userId'] as int;
          _ratings[uid] = 5.0;
          _comments[uid] = TextEditingController();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final client = ref.read(apiClientProvider);
      for (final p in _participants) {
        final uid = p['userId'] as int;
        await client.dio.post(
          '/api/gatherings/${widget.gatheringId}/reviews',
          data: {
            'revieweeId': uid,
            'rating': (_ratings[uid] ?? 5.0).round(),
            'comment': _comments[uid]?.text.trim().isEmpty == true
                ? null
                : _comments[uid]?.text.trim(),
          },
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 제출되었습니다!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? const Center(
                  child: Text(
                    '리뷰할 참여자가 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _participants.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 24),
                        itemBuilder: (context, i) {
                          final p = _participants[i];
                          final uid = p['userId'] as int;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF03C75A),
                                    child: Text(
                                      (p['nickname'] as String? ?? '?')
                                          .substring(0, 1),
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    p['nickname'] as String? ?? '알 수 없음',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: RatingBar.builder(
                                  initialRating: _ratings[uid] ?? 5.0,
                                  minRating: 1,
                                  itemCount: 5,
                                  itemSize: 40,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) =>
                                      setState(() => _ratings[uid] = rating),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _comments[uid],
                                decoration: InputDecoration(
                                  hintText: '한 줄 평을 남겨보세요 (선택)',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                ),
                                maxLength: 200,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03C75A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('리뷰 제출',
                                  style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
