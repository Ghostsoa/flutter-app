import 'package:flutter/material.dart';

class ChatSystemHint extends StatelessWidget {
  final String text;

  const ChatSystemHint({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
