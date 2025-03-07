import 'package:flutter/material.dart';
import '../../../data/models/story_message.dart';

class MessageBubble extends StatelessWidget {
  final StoryMessageUI message;
  final Color accentColor;
  final Function(String)? onActionSelected;

  const MessageBubble({
    super.key,
    required this.message,
    required this.accentColor,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 处理开场白
    if (message.type == StoryMessageUIType.opening) {
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
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: accentColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '开场白',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '故事开始',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.content,
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
    if (message.type == StoryMessageUIType.distillation) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message.content,
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
    if (message.type == StoryMessageUIType.userInput) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: accentColor,
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 处理临时消息（正在思考...或正在蒸馏...）
    if (message.content == '正在思考...' || message.content == '正在蒸馏对话...') {
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
                      message.content == '正在蒸馏对话...'
                          ? Colors.purple.withOpacity(0.7)
                          : Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.content,
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
        if (message.type == StoryMessageUIType.modelContent)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),

        // 系统提示
        if (message.type == StoryMessageUIType.modelPrompt)
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
                    message.content,
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
        if (message.type == StoryMessageUIType.modelActions &&
            message.actions != null)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var action in message.actions!)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () =>
                            onActionSelected?.call(action.keys.first),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          backgroundColor: accentColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: accentColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              color: accentColor,
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
