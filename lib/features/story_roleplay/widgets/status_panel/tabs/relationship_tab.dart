import 'package:flutter/material.dart';
import '../status_section.dart';

class RelationshipTab extends StatelessWidget {
  final Map<String, dynamic> relationships;

  const RelationshipTab({
    super.key,
    required this.relationships,
  });

  @override
  Widget build(BuildContext context) {
    final coreRelations = relationships['core_relations'] ?? {};
    final specialRelations = relationships['special_relations'] ?? [];
    final orgRelations = relationships['organization_relations'] ?? {};

    const accentColor = Color(0xFFFF80AB); // 粉红色

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusSection(
            title: '核心关系',
            icon: Icons.people_outline,
            items: {
              '盟友': (coreRelations['allies'] as List?)?.join('、') ?? '无',
              '敌对': (coreRelations['enemies'] as List?)?.join('、') ?? '无',
              '中立': (coreRelations['neutral'] as List?)?.join('、') ?? '无',
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '特殊关系',
            icon: Icons.star_border_outlined,
            items: {
              '关系列表': specialRelations.join('、') ?? '无',
            },
            accentColor: Colors.purpleAccent,
          ),
          const SizedBox(height: 16),
          StatusSection(
            title: '组织关系',
            icon: Icons.account_balance_outlined,
            items: {
              '友好组织': (orgRelations['friendly'] as List?)?.join('、') ?? '无',
              '敌对组织': (orgRelations['hostile'] as List?)?.join('、') ?? '无',
              '中立组织': (orgRelations['neutral'] as List?)?.join('、') ?? '无',
            },
            accentColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
