import 'package:flutter/material.dart';
import '../status_section.dart';

class EnvironmentTab extends StatelessWidget {
  final Map<String, dynamic> environment;

  const EnvironmentTab({
    super.key,
    required this.environment,
  });

  @override
  Widget build(BuildContext context) {
    final location = environment['location'] ?? {};
    final time = environment['time'] ?? {};
    final conditions = environment['conditions'] ?? {};

    const accentColor = Color(0xFF4FC3F7); // 浅蓝色

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusSection(
            title: '位置',
            icon: Icons.place_outlined,
            items: {
              '当前位置': location['main_location']?.toString() ?? '无',
              '相关位置': (location['sub_locations'] as List?)?.join('、') ?? '无',
              '特殊地点':
                  (location['special_locations'] as List?)?.join('、') ?? '无',
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '时间',
            icon: Icons.access_time_outlined,
            items: {
              '当前时间': time['current_time']?.toString() ?? '无',
              '时间限制': time['time_limit']?.toString() ?? '无',
              '特殊时间': time['special_time']?.toString() ?? '无',
            },
            accentColor: Colors.amberAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '环境条件',
            icon: Icons.cloud_outlined,
            items: {
              '天气': conditions['weather']?.toString() ?? '无',
              '氛围': conditions['atmosphere']?.toString() ?? '无',
              '特殊效果':
                  (conditions['special_effects'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }
}
