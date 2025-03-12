import 'package:flutter/material.dart';
import '../../../data/models/story_message.dart';
import '../services/audio_player_manager.dart';

class MessageBubble extends StatefulWidget {
  final StoryMessageUI message;
  final Color accentColor;
  final Function(String)? onActionSelected;
  final AudioPlayerManager audioPlayer;

  const MessageBubble({
    super.key,
    required this.message,
    required this.accentColor,
    required this.audioPlayer,
    this.onActionSelected,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    // 处理开场白
    if (widget.message.type == StoryMessageUIType.opening) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: widget.accentColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '开场白',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: widget.accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '故事开始',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.accentColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.message.content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    // 处理蒸馏内容
    if (widget.message.type == StoryMessageUIType.distillation) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.message.content,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
          ],
        ),
      );
    }

    // 处理用户输入
    if (widget.message.type == StoryMessageUIType.userInput) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: widget.accentColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.message.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 处理临时消息（正在思考...或正在蒸馏...）
    if (widget.message.content == '正在思考...' ||
        widget.message.content == '正在蒸馏对话...') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.message.content == '正在蒸馏对话...'
                          ? Colors.purple.withOpacity(0.7)
                          : Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 处理模型的内容
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主要内容
        if (widget.message.type == StoryMessageUIType.modelContent)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message.content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<PlaybackState>(
                        valueListenable: widget.audioPlayer.playbackState,
                        builder: (context, playbackState, child) {
                          final bool isCurrentText =
                              widget.audioPlayer.currentText ==
                                  widget.message.content;
                          final bool isPlaying = isCurrentText &&
                              playbackState == PlaybackState.playing;
                          final bool isLoading = isCurrentText &&
                              playbackState == PlaybackState.loading;

                          // 检查是否有缓存的音频ID
                          final bool hasCachedAudio =
                              widget.message.audioId != null;

                          return SizedBox(
                            width: 24,
                            height: 24,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        if (hasCachedAudio) {
                                          widget.audioPlayer
                                              .playTextWithAudioId(
                                            widget.message.content,
                                            widget.message.audioId!,
                                          );
                                        } else {
                                          widget.audioPlayer
                                              .playText(widget.message.content);
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      isLoading
                                          ? Icons.hourglass_empty
                                          : isPlaying
                                              ? Icons.stop_circle_outlined
                                              : Icons.play_circle_outline,
                                      size: 18,
                                      color: isPlaying || isLoading
                                          ? widget.accentColor
                                          : Colors.white.withOpacity(0.6),
                                    ),
                                    if (hasCachedAudio &&
                                        !isPlaying &&
                                        !isLoading)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: widget.accentColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // 系统提示
        if (widget.message.type == StoryMessageUIType.modelPrompt)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: Colors.amber[400],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.message.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[200],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 动作选项
        if (widget.message.type == StoryMessageUIType.modelActions &&
            widget.message.actions != null)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var action in widget.message.actions!)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () =>
                            widget.onActionSelected?.call(action.keys.first),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          backgroundColor: widget.accentColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: widget.accentColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              color: widget.accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              action.keys.first,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
