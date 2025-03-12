import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'group_chat_message.g.dart';

@JsonSerializable()
class GroupChatMessage {
  final String id;
  final String groupId;
  final String role;
  final String content;
  final DateTime createdAt;
  final bool isGreeting;
  final bool isDistilled;

  GroupChatMessage({
    String? id,
    required this.groupId,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isGreeting = false,
    this.isDistilled = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) =>
      _$GroupChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$GroupChatMessageToJson(this);

  GroupChatMessage copyWith({
    String? id,
    String? groupId,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isGreeting,
    bool? isDistilled,
  }) {
    return GroupChatMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isGreeting: isGreeting ?? this.isGreeting,
      isDistilled: isDistilled ?? this.isDistilled,
    );
  }
}

/// 群聊历史记录
class GroupChatHistory {
  final String groupId;
  final String xmlHistory;
  final List<GroupChatMessage> messages;
  final DateTime updatedAt;

  GroupChatHistory({
    required this.groupId,
    required this.xmlHistory,
    required this.messages,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory GroupChatHistory.empty(String groupId) {
    return GroupChatHistory(
      groupId: groupId,
      xmlHistory: '',
      messages: [],
    );
  }

  GroupChatHistory copyWith({
    String? groupId,
    String? xmlHistory,
    List<GroupChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return GroupChatHistory(
      groupId: groupId ?? this.groupId,
      xmlHistory: xmlHistory ?? this.xmlHistory,
      messages: messages ?? List.from(this.messages),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'xmlHistory': xmlHistory,
        'messages': messages.map((m) => m.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GroupChatHistory.fromJson(Map<String, dynamic> json) {
    return GroupChatHistory(
      groupId: json['groupId'] as String,
      xmlHistory: json['xmlHistory'] as String,
      messages: (json['messages'] as List)
          .map((m) => GroupChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
