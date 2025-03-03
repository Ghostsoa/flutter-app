import 'package:flutter/material.dart';

class ChatDistillingIndicator extends StatelessWidget {
  final bool isDistilling;

  const ChatDistillingIndicator({
    super.key,
    required this.isDistilling,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDistilling) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '正在整理对话记忆...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
