import 'package:flutter/material.dart';
import '../../../data/models/chat_archive.dart';
import '../../../data/models/chat_message.dart';
import 'chat_bubble.dart';
import 'chat_system_hint.dart';

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
  final bool Function(ChatMessage)? messageFilter;
  final Function(ChatMessage, String)? onMessageEdit;
  final WidgetBuilder? greetingBuilder;

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
    this.messageFilter,
    this.onMessageEdit,
    this.greetingBuilder,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  void _scrollToBottom() {
    if (widget.controller.hasClients && widget.archive.messages.isNotEmpty) {
      widget.controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessageEdit(ChatMessage message, String newContent) {
    widget.onMessageEdit?.call(message, newContent);
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
    final messages = widget.archive.uiMessages
        .where((msg) => widget.messageFilter?.call(msg) ?? true)
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        reverse: true,
        controller: widget.controller,
        padding: EdgeInsets.only(
          top: 100,
          bottom: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
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
          ...messages.reversed.map((message) {
            if (message.isSystemMessage) {
              if (widget.greetingBuilder != null &&
                  messages.indexOf(message) == 0) {
                return widget.greetingBuilder!(context);
              }
              return ChatSystemHint(text: message.content);
            }
            return ChatBubble(
              message: message,
              characterImageUrl: widget.characterImageUrl,
              useMarkdown: widget.useMarkdown,
              bubbleColor: message.isUser
                  ? widget.userBubbleColor
                  : widget.aiBubbleColor,
              textColor:
                  message.isUser ? widget.userTextColor : widget.aiTextColor,
              onEdit: (newContent) => _handleMessageEdit(message, newContent),
            );
          }),
        ],
      ),
    );
  }
}
