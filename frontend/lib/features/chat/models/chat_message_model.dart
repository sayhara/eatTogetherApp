class ChatMessageModel {
  final int? id;
  final int gatheringId;
  final int? senderId;
  final String senderNickname;
  final String content;
  final String type;
  final DateTime createdAt;

  const ChatMessageModel({
    this.id,
    required this.gatheringId,
    this.senderId,
    required this.senderNickname,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as int?,
        gatheringId: json['gatheringId'] as int,
        senderId: json['senderId'] as int?,
        senderNickname: json['senderNickname'] as String? ?? '',
        content: json['content'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isSystem => type == 'ENTER' || type == 'LEAVE';
}
