import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final Color accentColor;
  final VoidCallback? onUndo;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.accentColor,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onUndo != null)
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: onUndo,
                color: Colors.white70,
                tooltip: '撤销',
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: '输入对话内容...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
                color: Colors.white,
                onPressed: isLoading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
