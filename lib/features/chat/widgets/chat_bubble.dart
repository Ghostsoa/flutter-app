import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/chat_message.dart';
import '../services/chat_audio_player_manager.dart';
import 'audio_visualizer.dart';
import '../../../core/utils/text_formatter.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage? message;
  final bool useMarkdown;
  final String bubbleColor;
  final String textColor;
  final String? content;
  final Function(String)? onEdit;
  final ChatAudioPlayerManager? audioPlayer;

  const ChatBubble({
    super.key,
    required this.message,
    this.useMarkdown = false,
    required this.bubbleColor,
    required this.textColor,
    this.onEdit,
    this.audioPlayer,
  }) : content = null;

  /// 用于显示流式消息的构造函数
  const ChatBubble.streaming({
    super.key,
    required this.content,
    this.useMarkdown = false,
    required this.bubbleColor,
    required this.textColor,
    this.audioPlayer,
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
    final formattedContent = widget.useMarkdown
        ? TextFormatter.formatModelResponse(content)
        : content;
    final isUser = widget.message?.isUser ?? false;
    final bubbleColor = _hexToColor(widget.bubbleColor);
    final textColor = _hexToColor(widget.textColor);
    final hasAudioPlayer = widget.audioPlayer != null;
    final hasAudioId = widget.message?.audioId != null;

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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isEditing
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _editingController,
                                      focusNode: _editFocusNode,
                                      maxLines: null,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: textColor.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: textColor.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: textColor.withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: textColor.withOpacity(0.05),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isEditing = false;
                                              _editingController.text =
                                                  widget.message?.content ?? '';
                                            });
                                          },
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  textColor.withOpacity(0.1),
                                                  textColor.withOpacity(0.2),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '取消',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _handleSave,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  textColor.withOpacity(0.1),
                                                  textColor.withOpacity(0.2),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '确定',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : widget.useMarkdown
                                  ? MarkdownBody(
                                      data: formattedContent,
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                          height: 1.5,
                                          letterSpacing: 0.3,
                                        ),
                                        code: TextStyle(
                                          color: Colors.pink[100],
                                          backgroundColor: Colors.transparent,
                                          fontSize: 14,
                                          fontFamily: 'JetBrains Mono',
                                          height: 1.5,
                                        ),
                                        codeblockPadding:
                                            const EdgeInsets.all(16),
                                        codeblockDecoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: textColor.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        blockquote: TextStyle(
                                          color: textColor.withOpacity(0.9),
                                          fontSize: 15,
                                          height: 1.5,
                                          letterSpacing: 0.3,
                                        ),
                                        blockquoteDecoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              textColor.withOpacity(0.15),
                                              textColor.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border(
                                            left: BorderSide(
                                              color: Colors.blue[200]!
                                                  .withOpacity(0.5),
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        blockquotePadding:
                                            const EdgeInsets.fromLTRB(
                                                16, 12, 12, 12),
                                        h1: TextStyle(
                                          color: textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          height: 1.7,
                                        ),
                                        h2: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          height: 1.7,
                                        ),
                                        h3: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          height: 1.7,
                                        ),
                                        listBullet: TextStyle(
                                          color: textColor.withOpacity(0.8),
                                          fontSize: 15,
                                        ),
                                        listIndent: 24,
                                        listBulletPadding:
                                            const EdgeInsets.only(right: 8),
                                        strong: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        em: TextStyle(
                                          color: textColor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        horizontalRuleDecoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: textColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        tableHead: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        tableBody: TextStyle(
                                          color: textColor.withOpacity(0.9),
                                          fontSize: 15,
                                        ),
                                        tableBorder: TableBorder.all(
                                          color: textColor.withOpacity(0.2),
                                          width: 1,
                                          style: BorderStyle.solid,
                                        ),
                                        tableCellsPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        tableColumnWidth:
                                            const FlexColumnWidth(),
                                      ),
                                      selectable: true,
                                    )
                                  : Builder(
                                      builder: (context) {
                                        return RichText(
                                          text: TextSpan(
                                            children: TextFormatter
                                                .formatHighlightText(
                                              formattedContent,
                                              textColor: textColor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          if (!isUser &&
                              !_isEditing &&
                              (hasAudioPlayer || widget.message != null))
                            const SizedBox(height: 20), // 只在有按钮时添加底部间距
                        ],
                      ),
                      if (!isUser &&
                          !_isEditing &&
                          (hasAudioPlayer || widget.message != null))
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (hasAudioPlayer)
                                ValueListenableBuilder<ChatPlaybackState>(
                                  valueListenable:
                                      widget.audioPlayer!.playbackState,
                                  builder: (context, playbackState, child) {
                                    final bool isCurrentText =
                                        widget.audioPlayer!.currentText ==
                                            content;
                                    final bool isPlaying = isCurrentText &&
                                        playbackState ==
                                            ChatPlaybackState.playing;
                                    final bool isLoading = isCurrentText &&
                                        playbackState ==
                                            ChatPlaybackState.loading;

                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            textColor.withOpacity(0.1),
                                            textColor.withOpacity(0.2),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isLoading
                                              ? null
                                              : () {
                                                  if (hasAudioId) {
                                                    widget.audioPlayer!
                                                        .playTextWithAudioId(
                                                      content,
                                                      widget.message!.audioId!,
                                                    );
                                                  } else {
                                                    widget.audioPlayer!
                                                        .playText(content);
                                                  }
                                                },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isLoading
                                                    ? Icons.hourglass_empty
                                                    : isPlaying
                                                        ? Icons
                                                            .stop_circle_outlined
                                                        : Icons
                                                            .play_circle_outline,
                                                size: 16,
                                                color: isPlaying || isLoading
                                                    ? textColor
                                                    : textColor
                                                        .withOpacity(0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              if (isPlaying)
                                                AudioVisualizer(
                                                  audioPlayer: widget
                                                      .audioPlayer!.player,
                                                  color: textColor,
                                                  height: 16,
                                                  barCount: 12,
                                                )
                                              else
                                                Text(
                                                  '播放',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              if (hasAudioId &&
                                                  !isPlaying &&
                                                  !isLoading)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 4),
                                                  width: 4,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: textColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (widget.message != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isEditing) ...[
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isEditing = false;
                                            _editingController.text =
                                                widget.message?.content ?? '';
                                          });
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                textColor.withOpacity(0.1),
                                                textColor.withOpacity(0.2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.close,
                                                size: 16,
                                                color:
                                                    textColor.withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '取消',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _handleSave,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                textColor.withOpacity(0.1),
                                                textColor.withOpacity(0.2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check,
                                                size: 16,
                                                color:
                                                    textColor.withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '确定',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ] else
                                      GestureDetector(
                                        onTap: _handleEdit,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                textColor.withOpacity(0.1),
                                                textColor.withOpacity(0.2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color:
                                                    textColor.withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '编辑',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
