import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/gathering_model.dart';

final gatheringDetailProvider =
    FutureProvider.family<GatheringModel, int>((ref, id) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/gatherings/$id');
  return GatheringModel.fromJson((res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
});

final gatheringActionProvider =
    NotifierProvider<GatheringActionNotifier, bool>(
  GatheringActionNotifier.new,
);

class GatheringActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> join(int gatheringId) async {
    state = true;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/api/gatherings/$gatheringId/join');
      ref.invalidate(gatheringDetailProvider(gatheringId));
    } finally {
      state = false;
    }
  }

  Future<void> leave(int gatheringId) async {
    state = true;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .delete('/api/gatherings/$gatheringId/leave');
      ref.invalidate(gatheringDetailProvider(gatheringId));
    } finally {
      state = false;
    }
  }

  Future<void> complete(int gatheringId) async {
    state = true;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/api/gatherings/$gatheringId/complete');
      ref.invalidate(gatheringDetailProvider(gatheringId));
    } finally {
      state = false;
    }
  }
}
