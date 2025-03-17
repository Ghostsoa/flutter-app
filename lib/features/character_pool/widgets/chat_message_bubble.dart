import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:my_app/data/models/multimodal_message.dart';
import 'image_preview_dialog.dart';

class ChatMessageBubble extends StatelessWidget {
  final MultimodalMessage message;
  final Map<String, Uint8List> imageCache;
  final Function(Uint8List) onSaveImage;

  static const Color starBlue = Color(0xFF6B8CFF);
  static const Color dreamPurple = Color(0xFFB277FF);
  static const Color darkBg = Color(0xFF1A1B1E);
  static const Color lightText = Color(0xFFF0F0F0);

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.imageCache,
    required this.onSaveImage,
  });

  Widget _buildImageError() {
    return Container(
      width: 240,
      height: 240,
      color: darkBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            '图片加载失败',
            style: TextStyle(
              color: lightText.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return RepaintBoundary(
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isUser ? 64 : 16,
            right: isUser ? 16 : 16,
            top: 8,
            bottom: 8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUser
                  ? [starBlue, dreamPurple]
                  : [darkBg.withOpacity(0.7), darkBg.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUser ? Colors.transparent : starBlue.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUser ? dreamPurple : starBlue).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.text?.isNotEmpty ?? false)
                MarkdownBody(
                  data: message.text!.trim(),
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser ? lightText : lightText.withOpacity(0.9),
                      fontSize: 15,
                    ),
                    code: TextStyle(
                      color: isUser ? lightText : lightText.withOpacity(0.9),
                      fontSize: 14,
                      backgroundColor: darkBg.withOpacity(0.3),
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: darkBg.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (message.imageData != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: starBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        try {
                          final String cacheKey =
                              message.id + (message.imageData?.data ?? '');
                          if (!imageCache.containsKey(cacheKey)) {
                            try {
                              final imageData =
                                  base64Decode(message.imageData!.data);
                              imageCache[cacheKey] = imageData;
                              if (imageCache.length > 10) {
                                final oldestKey = imageCache.keys.first;
                                imageCache.remove(oldestKey);
                              }
                            } catch (e) {
                              return _buildImageError();
                            }
                          }
                          final imageData = imageCache[cacheKey]!;

                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ImagePreviewDialog(
                                  imageData: imageData,
                                  onSave: onSaveImage,
                                ),
                              );
                            },
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                                maxHeight: constraints.maxHeight * 0.4,
                              ),
                              child: Image.memory(
                                imageData,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          );
                        } catch (e) {
                          return _buildImageError();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
