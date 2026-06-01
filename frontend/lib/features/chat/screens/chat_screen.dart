import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/gathering_model.dart';
import '../../gathering/providers/gathering_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatMessagesProvider.notifier).clear();
      _loadHistoryAndConnect();
    });
  }

  Future<void> _loadHistoryAndConnect() async {
    try {
      final history = await ref.read(chatHistoryProvider(widget.gatheringId).future);
      if (mounted) {
        ref.read(chatMessagesProvider.notifier).loadHistory(history);
      }
    } catch (_) {}
    _connectStomp();
  }

  Future<void> _connectStomp() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();
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
        ref.read(chatMessagesProvider.notifier).addMessage(ChatMessageModel.fromJson(json));
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
      destination: '/app/chat/${widget.gatheringId}',
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
    final gatheringAsync = ref.watch(gatheringDetailProvider(widget.gatheringId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.gatheringTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Icon(
            Icons.circle,
            size: 10,
            color: _connected ? const Color(0xFF03C75A) : Colors.grey,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 모임 정보 카드
          gatheringAsync.when(
            data: (g) => _GatheringInfoCard(gathering: g, gatheringId: widget.gatheringId),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),

          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                message: messages[i],
                isMine: messages[i].senderId == currentUser?.id,
              ),
            ),
          ),

          // 입력창
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

class _GatheringInfoCard extends StatelessWidget {
  final GatheringModel gathering;
  final int gatheringId;
  const _GatheringInfoCard({required this.gathering, required this.gatheringId});

  @override
  Widget build(BuildContext context) {
    final isOpen = gathering.status == 'OPEN';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gathering.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${gathering.currentParticipants}명 참여중',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFFFFD600) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOpen ? '모집중' : '마감',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.content, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final timeFmt = DateFormat('a h:mm', 'ko');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF03C75A),
              child: Text(
                message.senderNickname.isNotEmpty ? message.senderNickname[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(message.senderNickname, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMine) ...[
                    Text(timeFmt.format(message.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.58),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine ? const Color(0xFFFFD600) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.black87 : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!isMine) ...[
                    const SizedBox(width: 4),
                    Text(timeFmt.format(message.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: enabled ? '메시지를 입력하세요' : '연결 중...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFFFD600) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
