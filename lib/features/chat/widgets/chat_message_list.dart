import 'package:flutter/material.dart';
import '../../../data/models/chat_archive.dart';
import 'chat_bubble.dart';

class ChatMessageList extends StatefulWidget {
  final ScrollController controller;
  final ChatArchive archive;
  final bool useMarkdown;
  final String? characterImageUrl;
  final String userBubbleColor;
  final String aiBubbleColor;
  final String userTextColor;
  final String aiTextColor;
  final String streamingText;

  const ChatMessageList({
    super.key,
    required this.controller,
    required this.archive,
    required this.characterImageUrl,
    this.useMarkdown = false,
    required this.userBubbleColor,
    required this.aiBubbleColor,
    required this.userTextColor,
    required this.aiTextColor,
    this.streamingText = '',
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  void _scrollToBottom() {
    if (widget.controller.hasClients && widget.archive.messages.isNotEmpty) {
      widget.controller.jumpTo(0); // 因为使用了 reverse: true，所以滚动到 0 就是滚动到最新消息
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 只在有新消息或流式响应更新时滚动
    if (oldWidget.archive.messages.length != widget.archive.messages.length ||
        oldWidget.streamingText != widget.streamingText) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ListView(
        controller: widget.controller,
        reverse: true,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          bottom: 100,
          left: 16,
          right: 16,
        ),
        children: [
          if (widget.streamingText.isNotEmpty)
            ChatBubble.streaming(
              content: widget.streamingText,
              characterImageUrl: widget.characterImageUrl,
              useMarkdown: widget.useMarkdown,
              bubbleColor: widget.aiBubbleColor,
              textColor: widget.aiTextColor,
            ),
          ...widget.archive.messages.reversed.map((message) {
            return ChatBubble(
              message: message,
              characterImageUrl: widget.characterImageUrl,
              useMarkdown: widget.useMarkdown,
              bubbleColor: message.isUser
                  ? widget.userBubbleColor
                  : widget.aiBubbleColor,
              textColor:
                  message.isUser ? widget.userTextColor : widget.aiTextColor,
            );
          }),
        ],
      ),
    );
  }
}
