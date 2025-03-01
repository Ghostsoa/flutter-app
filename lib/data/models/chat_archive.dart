import 'package:json_annotation/json_annotation.dart';
import 'chat_message.dart';

part 'chat_archive.g.dart';

@JsonSerializable()
class ChatArchive {
  final String id;
  final String characterId;
  final String name;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;

  ChatArchive({
    required this.id,
    required this.characterId,
    required this.name,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
  });

  factory ChatArchive.fromJson(Map<String, dynamic> json) =>
      _$ChatArchiveFromJson(json);
  Map<String, dynamic> toJson() => _$ChatArchiveToJson(this);

  ChatArchive copyWith({
    String? id,
    String? characterId,
    String? name,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
  }) {
    return ChatArchive(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }
}
