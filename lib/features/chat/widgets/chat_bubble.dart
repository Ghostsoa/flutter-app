import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/chat_message.dart';
import 'dart:io';

class ChatBubble extends StatefulWidget {
  final ChatMessage? message;
  final String? characterImageUrl;
  final bool useMarkdown;
  final String bubbleColor;
  final String textColor;
  final String? content;
  final Function(String)? onEdit;

  const ChatBubble({
    super.key,
    required this.message,
    this.characterImageUrl,
    this.useMarkdown = false,
    required this.bubbleColor,
    required this.textColor,
    this.onEdit,
  }) : content = null;

  /// 用于显示流式消息的构造函数
  const ChatBubble.streaming({
    super.key,
    required this.content,
    this.characterImageUrl,
    this.useMarkdown = false,
    required this.bubbleColor,
    required this.textColor,
  })  : message = null,
        onEdit = null;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;
  final _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(
      text: widget.message?.content ?? widget.content ?? '',
    );
  }

  @override
  void dispose() {
    _editingController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _handleEdit() {
    setState(() {
      _isEditing = true;
      _editingController.text = widget.message?.content ?? '';
    });
    _editFocusNode.requestFocus();
  }

  void _handleSave() {
    final newContent = _editingController.text.trim();
    if (newContent.isNotEmpty && newContent != widget.message?.content) {
      widget.onEdit?.call(newContent);
    }
    setState(() => _isEditing = false);
  }

  void _handleCopy() {
    final content = widget.message?.content ?? widget.content ?? '';
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

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
              color: _hexToColor(widget.bubbleColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hexToColor(widget.bubbleColor).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _hexToColor(widget.bubbleColor),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hexToColor(widget.bubbleColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _hexToColor(widget.textColor),
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
    final content = widget.message?.content ?? widget.content ?? '';
    final isUser = widget.message?.isUser ?? false;
    final bubbleColor = _hexToColor(widget.bubbleColor);
    final textColor = _hexToColor(widget.textColor);

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
              if (!isUser && widget.characterImageUrl != null) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.characterImageUrl!.startsWith('/')
                      ? FileImage(File(widget.characterImageUrl!))
                      : NetworkImage(widget.characterImageUrl!)
                          as ImageProvider,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isEditing
                          ? TextField(
                              controller: _editingController,
                              focusNode: _editFocusNode,
                              maxLines: null,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: _handleSave,
                                  color: textColor,
                                ),
                              ),
                            )
                          : widget.useMarkdown
                              ? MarkdownBody(
                                  data: content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                    code: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                      backgroundColor:
                                          Colors.black.withOpacity(0.3),
                                      fontSize: 14,
                                    ),
                                  ),
                                  selectable: true,
                                )
                              : Text(
                                  content,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                ),
                    ),
                    if (!_isEditing && widget.message != null && !isUser)
                      Positioned(
                        right: 0,
                        bottom: -24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onPressed: _handleEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 24,
                              ),
                              splashRadius: 16,
                              tooltip: '编辑',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // 显示状态信息
          if (!isUser && widget.message?.statusInfo != null)
            _buildStatusInfo(context, widget.message!.statusInfo!),
        ],
      ),
    );
  }
}
