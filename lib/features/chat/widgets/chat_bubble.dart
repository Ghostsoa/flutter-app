import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/chat_message.dart';
import 'dart:io';

class ChatBubble extends StatelessWidget {
  final ChatMessage? message;
  final String? content;
  final bool useMarkdown;
  final String? characterImageUrl;
  final String bubbleColor;
  final String textColor;

  const ChatBubble({
    super.key,
    required this.message,
    this.content,
    required this.characterImageUrl,
    required this.bubbleColor,
    required this.textColor,
    this.useMarkdown = false,
  });

  /// 用于显示流式消息的构造函数
  const ChatBubble.streaming({
    super.key,
    required this.content,
    required this.characterImageUrl,
    required this.bubbleColor,
    required this.textColor,
    this.useMarkdown = false,
  }) : message = null;

  // 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 8) {
      // 如果包含透明度
      return Color(int.parse(hexColor, radix: 16));
    } else if (hexColor.length == 6) {
      // 如果不包含透明度，添加完全不透明的透明度
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    // 默认返回黑色
    return Colors.black;
  }

  Widget _buildStatusInfo(BuildContext context, String statusInfo) {
    final statuses = statusInfo
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 40),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: statuses.map((status) {
          final parts = status.split(':').map((s) => s.trim()).toList();
          if (parts.length != 2) return const SizedBox();

          final name = parts[0].replaceAll(RegExp(r'[\[\]]'), '');
          final value = parts[1].replaceAll(RegExp(r'[\[\]]'), '');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _hexToColor(bubbleColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hexToColor(bubbleColor).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _hexToColor(bubbleColor),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hexToColor(bubbleColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _hexToColor(textColor),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message?.isUser ?? false;
    final displayContent = message?.content ?? content ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser && characterImageUrl != null) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: characterImageUrl!.startsWith('/')
                      ? FileImage(File(characterImageUrl!))
                      : NetworkImage(characterImageUrl!) as ImageProvider,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _hexToColor(bubbleColor),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: useMarkdown
                      ? MarkdownBody(
                          data: displayContent,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: _hexToColor(textColor),
                              fontSize: 16,
                            ),
                            code: TextStyle(
                              color: _hexToColor(textColor).withOpacity(0.8),
                              backgroundColor: Colors.black.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                          selectable: true,
                        )
                      : SelectableText(
                          displayContent,
                          style: TextStyle(
                            color: _hexToColor(textColor),
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
          // 显示状态信息
          if (!isUser && message?.statusInfo != null)
            _buildStatusInfo(context, message!.statusInfo!),
        ],
      ),
    );
  }
}
