import 'package:flutter/material.dart';
import '../status_section.dart';

class QuestTab extends StatelessWidget {
  final Map<String, dynamic> quests;

  const QuestTab({
    super.key,
    required this.quests,
  });

  @override
  Widget build(BuildContext context) {
    final mainQuest = quests['main_quest'] ?? {};
    final sideQuests = quests['side_quests'] ?? [];
    final obstacles = quests['obstacles'] ?? {};

    const accentColor = Color(0xFFF06292); // 粉色

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusSection(
            title: '主线任务',
            icon: Icons.star_outline,
            items: {
              '任务': mainQuest['title']?.toString() ?? '无',
              '描述': mainQuest['description']?.toString() ?? '无',
              '进度': mainQuest['progress']?.toString() ?? '0%',
              '奖励': (mainQuest['rewards'] as List?)?.join('、') ?? '无',
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '支线任务',
            icon: Icons.extension_outlined,
            items: {
              for (var quest in sideQuests)
                quest['title']?.toString() ?? '未知任务':
                    quest['description']?.toString() ?? '无描述',
            },
            accentColor: Colors.purpleAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '障碍',
            icon: Icons.warning_amber_outlined,
            items: {
              '当前': (obstacles['current'] as List?)?.join('、') ?? '无',
              '潜在': (obstacles['potential'] as List?)?.join('、') ?? '无',
              '特殊': (obstacles['special'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}
