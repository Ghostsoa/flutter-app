import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final Map<String, dynamic> statusUpdates;

  const StatusCard({
    super.key,
    required this.statusUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final character = statusUpdates['character'] ?? {};
    final basicStatus = character['basic_status'] ?? {};
    final environment = statusUpdates['environment'] ?? {};
    final location = environment['location'] ?? {};
    final quests = statusUpdates['quests'] ?? {};
    final mainQuest = quests['main_quest'] ?? {};
    final sideQuests = quests['side_quests'] as List? ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：生命、能量、位置
        Row(
          children: [
            Expanded(
              child: _buildBasicItem(
                Icons.favorite_outline,
                basicStatus['health']?.toString() ?? '100',
                Colors.redAccent,
              ),
            ),
            Container(width: 1, color: Colors.white10),
            Expanded(
              child: _buildBasicItem(
                Icons.bolt,
                basicStatus['energy']?.toString() ?? '100',
                Colors.amberAccent,
              ),
            ),
            Container(width: 1, color: Colors.white10),
            Expanded(
              child: _buildBasicItem(
                Icons.location_on_outlined,
                location['main_location']?.toString() ?? '未知',
                Colors.blueAccent,
              ),
            ),
          ],
        ),
        Container(height: 1, color: Colors.white10),
        // 第二行：任务和状态
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildBasicItem(
                Icons.assignment_outlined,
                mainQuest['title']?.toString() ?? '无',
                Colors.greenAccent,
                suffix: sideQuests.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${sideQuests.length}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Container(width: 1, color: Colors.white10),
            Expanded(
              child: _buildBasicItem(
                Icons.sentiment_satisfied_alt_outlined,
                basicStatus['mood']?.toString() ?? '正常',
                Colors.deepPurpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicItem(IconData icon, String text, Color color,
      {Widget? suffix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffix != null) suffix,
      ],
    );
  }
}
