import 'package:flutter/material.dart';
import '../status_section.dart';

class CharacterTab extends StatelessWidget {
  final Map<String, dynamic> character;
  final Map<String, dynamic> statusEffects;

  const CharacterTab({
    super.key,
    required this.character,
    required this.statusEffects,
  });

  @override
  Widget build(BuildContext context) {
    final basicStatus = character['basic_status'] ?? {};
    final attributes = character['attributes'] ?? {};
    final skills = character['skills'] ?? {};
    final identity = character['identity'] ?? {};

    const accentColor = Color(0xFF64B5F6);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusSection(
            title: '基本信息',
            icon: Icons.person_outline,
            items: {
              '姓名': character['name']?.toString() ?? '无',
              '外表': character['appearance']?.toString() ?? '无',
              '主要身份': identity['main_identity']?.toString() ?? '无',
              '特殊身份': identity['special_identity']?.toString() ?? '无',
              '声望': identity['reputation']?.toString() ?? '无',
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '状态',
            icon: Icons.favorite_outline,
            items: {
              '生命值': basicStatus['health']?.toString() ?? '100',
              '能量值': basicStatus['energy']?.toString() ?? '100',
              '情绪': basicStatus['mood']?.toString() ?? '正常',
            },
            accentColor: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '属性',
            icon: Icons.auto_awesome,
            items: {
              '主属性': attributes['main_attribute']?.toString() ?? '无',
              '次要属性': (attributes['sub_attributes'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.amberAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '技能',
            icon: Icons.psychology,
            items: {
              '基础技能': (skills['basic_skills'] as List?)?.join('、') ?? '无',
              '特殊技能': (skills['special_skills'] as List?)?.join('、') ?? '无',
              '潜在技能': (skills['potential_skills'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.greenAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '状态效果',
            icon: Icons.local_fire_department,
            items: {
              '增益效果': (statusEffects['buffs'] as List?)?.join('、') ?? '无',
              '减益效果': (statusEffects['debuffs'] as List?)?.join('、') ?? '无',
              '特殊效果':
                  (statusEffects['special_effects'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }
}
