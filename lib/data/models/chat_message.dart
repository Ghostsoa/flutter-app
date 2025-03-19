import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? statusInfo;
  final bool isSystemMessage; // 是否是系统消息
  final String? audioId; // 音频ID，用于缓存

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.statusInfo,
    this.isSystemMessage = false,
    this.audioId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? statusInfo,
    bool? isSystemMessage,
    String? audioId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      statusInfo: statusInfo ?? this.statusInfo,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      audioId: audioId ?? this.audioId,
    );
  }
}
