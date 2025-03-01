import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? statusInfo; // 存储状态信息，格式如 "生命值:100,心情:开心,能量:80"

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.statusInfo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// 从原始内容中提取状态信息，并返回清理后的内容
  static (String cleanContent, String? statusInfo) extractStatusInfo(
      String rawContent) {
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(rawContent);
    String? foundStatus;

    // 查找最后一个可能的状态信息
    for (final match in matches) {
      final content = match.group(1);
      if (content != null && content.contains(':')) {
        // 检查是否符合状态格式（key:value 对）
        final parts = content.split(',');
        bool isStatus = parts.every((part) => part.trim().contains(':'));
        if (isStatus) {
          foundStatus = content;
        }
      }
    }

    if (foundStatus != null) {
      // 移除状态信息并清理多余的空行
      final cleanContent = rawContent
          .replaceAll('[$foundStatus]', '')
          .replaceAll(RegExp(r'\n\s*\n'), '\n')
          .trim();
      return (cleanContent, foundStatus);
    }

    return (rawContent, null);
  }
}
