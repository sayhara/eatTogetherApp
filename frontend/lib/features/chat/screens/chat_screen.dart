import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int gatheringId;
  final String gatheringTitle;

  const ChatScreen({
    super.key,
    required this.gatheringId,
    required this.gatheringTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  StompClient? _stompClient;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    ref.read(chatMessagesProvider.notifier).clear();
    _loadHistoryAndConnect();
  }

  Future<void> _loadHistoryAndConnect() async {
    try {
      final history = await ref.read(
        chatHistoryProvider(widget.gatheringId).future,
      );
      if (mounted) {
        ref.read(chatMessagesProvider.notifier).loadHistory(history);
      }
    } catch (_) {}
    _connectStomp();
  }

  Future<void> _connectStomp() async {
    final token =
        await ref.read(tokenStorageProvider).getAccessToken();
    _stompClient = StompClient(
      config: StompConfig(
        url: '${AppConstants.baseUrl.replaceFirst('http', 'ws')}/ws',
        onConnect: _onConnected,
        onStompError: (frame) {},
        onDisconnect: (_) {
          if (mounted) setState(() => _connected = false);
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _stompClient!.activate();
  }

  void _onConnected(StompFrame frame) {
    if (mounted) setState(() => _connected = true);

    _stompClient?.subscribe(
      destination: '/topic/gathering/${widget.gatheringId}',
      callback: (frame) {
        if (frame.body == null || !mounted) return;
        final json = jsonDecode(frame.body!) as Map<String, dynamic>;
        ref
            .read(chatMessagesProvider.notifier)
            .addMessage(ChatMessageModel.fromJson(json));
        _scrollToBottom();
      },
    );

    _stompClient?.send(
      destination: '/app/chat/${widget.gatheringId}/enter',
      body: '{}',
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_connected) return;
    _stompClient?.send(
      destination: '/app/chat/${widget.gatheringId}/send',
      body: jsonEncode({'content': text, 'type': 'CHAT'}),
    );
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final currentUser = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.gatheringTitle,
                style: const TextStyle(fontSize: 16)),
            Text(
              _connected ? '연결됨' : '연결 중...',
              style: TextStyle(
                fontSize: 12,
                color: _connected ? Colors.greenAccent : Colors.grey.shade300,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                message: messages[i],
                isMine: messages[i].senderId == currentUser?.id,
              ),
            ),
          ),
          _ChatInput(
            controller: _controller,
            enabled: _connected,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final timeFmt = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF03C75A),
              child: Text(
                message.senderNickname.isNotEmpty
                    ? message.senderNickname[0]
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.senderNickname,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMine)
                    Text(
                      timeFmt.format(message.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  if (isMine) const SizedBox(width: 4),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMine
                          ? const Color(0xFF03C75A)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 0),
                        bottomRight: Radius.circular(isMine ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (!isMine) const SizedBox(width: 4),
                  if (!isMine)
                    Text(
                      timeFmt.format(message.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: enabled ? '메시지를 입력하세요' : '연결 중...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: enabled
                ? const Color(0xFF03C75A)
                : Colors.grey,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: enabled ? onSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
