import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message_model.dart';

final chatHistoryProvider =
    FutureProvider.family<List<ChatMessageModel>, int>(
        (ref, gatheringId) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/chat/$gatheringId/history');
  final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  return list
      .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessageModel>>(
  ChatMessagesNotifier.new,
);

class ChatMessagesNotifier extends Notifier<List<ChatMessageModel>> {
  @override
  List<ChatMessageModel> build() => [];

  void loadHistory(List<ChatMessageModel> history) => state = history;

  void addMessage(ChatMessageModel msg) => state = [...state, msg];

  void clear() => state = [];
}
