import 'package:flutter/material.dart';
import 'tabs/character_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/quest_tab.dart';
import 'tabs/relationship_tab.dart';
import 'tabs/environment_tab.dart';

class StatusTabView extends StatelessWidget {
  final Map<String, dynamic> statusUpdates;
  final ScrollController scrollController;

  const StatusTabView({
    super.key,
    required this.statusUpdates,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(text: '角色'),
              Tab(text: '背包'),
              Tab(text: '任务'),
              Tab(text: '关系'),
              Tab(text: '环境'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: CharacterTab(
                    character: statusUpdates['character'] ?? {},
                    statusEffects: statusUpdates['status_effects'] ?? {},
                  ),
                ),
                SingleChildScrollView(
                  controller: scrollController,
                  child: InventoryTab(
                    inventory: statusUpdates['inventory'] ?? {},
                  ),
                ),
                SingleChildScrollView(
                  controller: scrollController,
                  child: QuestTab(
                    quests: statusUpdates['quests'] ?? {},
                  ),
                ),
                SingleChildScrollView(
                  controller: scrollController,
                  child: RelationshipTab(
                    relationships: statusUpdates['relationships'] ?? {},
                  ),
                ),
                SingleChildScrollView(
                  controller: scrollController,
                  child: EnvironmentTab(
                    environment: statusUpdates['environment'] ?? {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
