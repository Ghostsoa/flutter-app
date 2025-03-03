import 'package:flutter/material.dart';

class ChatEmptyState extends StatelessWidget {
  final VoidCallback onCreateArchive;

  const ChatEmptyState({
    super.key,
    required this.onCreateArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '没有可用的存档',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreateArchive,
                icon: const Icon(Icons.add),
                label: const Text('新建存档'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
