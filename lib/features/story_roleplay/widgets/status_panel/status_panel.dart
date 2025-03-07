import 'package:flutter/material.dart';
import 'status_tab_view.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> statusUpdates;
  final ScrollController scrollController;

  const StatusPanel({
    super.key,
    required this.statusUpdates,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 拖动条
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '状态面板',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 选项卡视图
          Expanded(
            child: StatusTabView(
              statusUpdates: statusUpdates,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}
