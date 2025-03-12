import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../data/models/group_chat.dart';
import '../../../data/models/group_chat_role.dart';

class GroupChatHeader extends StatefulWidget {
  final GroupChat group;
  final ValueChanged<GroupChatRole> onRoleClick;
  final Map<String, Image>? imageCache;
  final VoidCallback? onUndo;
  final VoidCallback? onReset;
  final bool canUndo;

  const GroupChatHeader({
    super.key,
    required this.group,
    required this.onRoleClick,
    this.imageCache,
    this.onUndo,
    this.onReset,
    this.canUndo = false,
  });

  @override
  State<GroupChatHeader> createState() => _GroupChatHeaderState();
}

class _GroupChatHeaderState extends State<GroupChatHeader> {
  final _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.group.roles.length}个角色',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.canUndo)
                IconButton(
                  icon: const Icon(
                    Icons.undo_rounded,
                    color: Colors.white,
                  ),
                  onPressed: widget.onUndo,
                  tooltip: '撤销上一条消息',
                ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text('重置对话'),
                        ],
                      ),
                      content: const Text('确定要清除所有对话记录并重新开始吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onReset?.call();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: '重置对话',
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return IconButton(
                    icon: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    onPressed: () {
                      _isExpandedNotifier.value = !isExpanded;
                    },
                  );
                },
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isExpandedNotifier,
            builder: (context, isExpanded, _) {
              return AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.group.roles.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final role = widget.group.roles[index];
                      return GestureDetector(
                        onTap: () => widget.onRoleClick(role),
                        child: Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: (role.avatarUrl != null)
                                      ? (widget.imageCache?[role.name] ??
                                          Image.memory(
                                            base64Decode(role.avatarUrl!),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          ))
                                      : Icon(
                                          Icons.person_outline,
                                          size: 28,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              );
            },
          ),
        ],
      ),
    );
  }
}
