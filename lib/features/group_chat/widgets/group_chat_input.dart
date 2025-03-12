import 'package:flutter/material.dart';

class GroupChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const GroupChatInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  void _insertParentheses(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start == -1 ? 0 : selection.start;
    final end = selection.end == -1 ? 0 : selection.end;

    final newText = text.replaceRange(start, end, '()');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + 1, // 将光标定位到括号中间
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _insertParentheses(controller),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '说点什么...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: 36,
            height: 36,
            child: Material(
              color: isLoading ? Colors.transparent : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: isLoading ? null : onSend,
                borderRadius: BorderRadius.circular(12),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
