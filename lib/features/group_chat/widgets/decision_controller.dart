import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../data/models/group_chat_role.dart';

class DecisionController extends StatefulWidget {
  final bool showDecisionProcess;
  final List<GroupChatRole> allRoles;
  final List<String> selectedSpeakers;
  final ValueChanged<List<String>> onSpeakersChanged;
  final VoidCallback onConfirm;
  final Map<String, Image>? imageCache;

  const DecisionController({
    super.key,
    required this.showDecisionProcess,
    required this.allRoles,
    required this.selectedSpeakers,
    required this.onSpeakersChanged,
    required this.onConfirm,
    this.imageCache,
  });

  @override
  State<DecisionController> createState() => _DecisionControllerState();
}

class _DecisionControllerState extends State<DecisionController> {
  late List<String> _speakers;

  @override
  void initState() {
    super.initState();
    _speakers = List<String>.from(widget.selectedSpeakers);
    if (_speakers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSpeakersChanged(_speakers);
      });
    }
  }

  @override
  void didUpdateWidget(DecisionController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedSpeakers, widget.selectedSpeakers)) {
      setState(() {
        _speakers = List<String>.from(widget.selectedSpeakers);
      });
      widget.onSpeakersChanged(_speakers);
    }
  }

  void _addSpeaker(GroupChatRole role) {
    if (!_speakers.contains(role.name)) {
      setState(() {
        _speakers.add(role.name);
      });
      widget.onSpeakersChanged(_speakers);
    }
  }

  void _removeSpeaker(String roleName) {
    setState(() {
      _speakers.remove(roleName);
    });
    widget.onSpeakersChanged(_speakers);
  }

  void _reorderSpeakers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _speakers.removeAt(oldIndex);
      _speakers.insert(newIndex, item);
    });
    widget.onSpeakersChanged(_speakers);
  }

  Widget _buildRoleAvatar(GroupChatRole role, {bool isSelected = false}) {
    return Container(
      width: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: (role.avatarUrl != null)
                      ? (widget.imageCache?[role.name] ??
                          Image.memory(
                            base64Decode(role.avatarUrl!),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 80,
                            cacheHeight: 80,
                          ))
                      : Icon(
                          Icons.person_outline,
                          size: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => _removeSpeaker(role.name),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 10,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            role.name,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.showDecisionProcess
        // 显示角色排序控制器
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 已选择的发言者(可拖拽排序)
              if (_speakers.isNotEmpty)
                Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    onReorder: _reorderSpeakers,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        child: child,
                      );
                    },
                    children: [
                      for (int i = 0; i < _speakers.length; i++)
                        ReorderableDragStartListener(
                          key: ValueKey(_speakers[i]),
                          index: i,
                          child: Center(
                            child: _buildRoleAvatar(
                              widget.allRoles.firstWhere(
                                (r) => r.name == _speakers[i],
                              ),
                              isSelected: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // 可选择的角色列表
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: widget.allRoles.length,
                        itemBuilder: (context, index) {
                          final role = widget.allRoles[index];
                          final isSelected = _speakers.contains(role.name);
                          if (isSelected) return const SizedBox.shrink();
                          return Center(
                            child: GestureDetector(
                              onTap: () => _addSpeaker(role),
                              child: _buildRoleAvatar(role),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton(
                        onPressed: _speakers.isEmpty ? null : widget.onConfirm,
                        icon: const Icon(Icons.check_circle_outline),
                        color: Colors.white,
                        tooltip: '确认发言顺序',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        // 显示决策提示
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI正在根据对话内容决定下一步发言者...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}
