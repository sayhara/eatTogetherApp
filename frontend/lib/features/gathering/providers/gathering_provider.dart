import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/gathering_model.dart';

final gatheringDetailProvider =
    FutureProvider.family<GatheringModel, int>((ref, id) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/gatherings/$id');
  return GatheringModel.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
});

// Returns: "NONE" | "PENDING" | "APPROVED" | "REJECTED"
final myParticipationStatusProvider =
    FutureProvider.family<String, int>((ref, gatheringId) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/gatherings/$gatheringId/my-status');
  return (res.data as Map<String, dynamic>)['data'] as String;
});

final pendingParticipantsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, gatheringId) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/gatherings/$gatheringId/participants/pending');
  final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
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
      ref.invalidate(myParticipationStatusProvider(gatheringId));
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
      ref.invalidate(myParticipationStatusProvider(gatheringId));
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

  Future<void> approve(int gatheringId, int targetUserId) async {
    state = true;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/api/gatherings/$gatheringId/participants/$targetUserId/approve');
      ref.invalidate(gatheringDetailProvider(gatheringId));
      ref.invalidate(pendingParticipantsProvider(gatheringId));
    } finally {
      state = false;
    }
  }

  Future<void> reject(int gatheringId, int targetUserId) async {
    state = true;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/api/gatherings/$gatheringId/participants/$targetUserId/reject');
      ref.invalidate(pendingParticipantsProvider(gatheringId));
    } finally {
      state = false;
    }
  }
}
