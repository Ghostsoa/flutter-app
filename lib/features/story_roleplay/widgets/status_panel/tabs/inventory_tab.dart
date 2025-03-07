import 'package:flutter/material.dart';
import '../status_section.dart';

class InventoryTab extends StatelessWidget {
  final Map<String, dynamic> inventory;

  const InventoryTab({
    super.key,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final bag = inventory['背包'] ?? {};
    final equipment = inventory['装备'] ?? {};
    final resources = inventory['resources'] ?? {};

    const accentColor = Color(0xFFFFB74D); // 橙色

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusSection(
            title: '背包',
            icon: Icons.backpack,
            items: {
              '常用物品': (bag['common_items'] as List?)?.join('、') ?? '无',
              '特殊物品': (bag['special_items'] as List?)?.join('、') ?? '无',
              '关键物品': (bag['key_items'] as List?)?.join('、') ?? '无',
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '装备',
            icon: Icons.shield_outlined,
            items: {
              '主要装备': (equipment['main_equipment'] as List?)?.join('、') ?? '无',
              '辅助装备':
                  (equipment['secondary_equipment'] as List?)?.join('、') ?? '无',
              '特殊装备':
                  (equipment['special_equipment'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '资源',
            icon: Icons.diamond_outlined,
            items: {
              '主要资源': resources['main_resource']?.toString() ?? '无',
              '次要资源': (resources['sub_resources'] as List?)?.join('、') ?? '无',
              '特殊资源':
                  (resources['special_resources'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }
}
