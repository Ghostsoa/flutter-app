import 'package:flutter/material.dart';
import 'dart:convert';
import './create_group_chat_screen.dart';
import '../../../data/repositories/group_chat_repository.dart';
import '../../../data/models/group_chat.dart';
import 'package:file_picker/file_picker.dart';
import './group_chat_detail_screen.dart';

class GroupChatListScreen extends StatefulWidget {
  const GroupChatListScreen({super.key});

  @override
  State<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends State<GroupChatListScreen> {
  final List<GroupChat> _groups = [];
  late final GroupChatRepository _repository;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = await GroupChatRepository.create();
    await _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _repository.getAllGroupChats();
      if (mounted) {
        setState(() {
          _groups.clear();
          _groups.addAll(groups);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载群聊失败：$e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToCreateGroup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CreateGroupChatScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadGroups();
    }
  }

  Future<void> _navigateToEditGroup(GroupChat group) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateGroupChatScreen(group: group),
      ),
    );

    if (result == true && mounted) {
      await _loadGroups();
    }
  }

  Future<void> _exportGroup(GroupChat group) async {
    try {
      // 将群聊数据转换为JSON字符串
      final jsonData = jsonEncode(group.toJson());

      // 生成文件名
      final fileName = '${group.name}(群聊).json';

      // 让用户选择保存位置
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData), // 提供字节数组
      );

      if (result == null || !mounted) return; // 用户取消了保存

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将群聊【${group.name}】导出到：$result'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '确定',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _deleteGroup(GroupChat group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除群聊'),
        content: Text('确定要删除群聊【${group.name}】吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _repository.deleteGroupChat(group.id);
        await _loadGroups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  Widget _buildGroupCard(GroupChat group) {
    final theme = Theme.of(context);
    final hasBackground = group.backgroundImageData != null;
    final roleCount = group.roles.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupChatDetailScreen(group: group),
            ),
          );
        },
        child: Stack(
          children: [
            // 背景图片或渐变
            if (hasBackground)
              Image.memory(
                base64Decode(group.backgroundImageData!),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            // 内容遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // 群聊名称
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 角色数量和功能标签
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$roleCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (group.showDecisionProcess)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // 更多按钮
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                group.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(
                                Icons.edit_outlined,
                                color: theme.colorScheme.onSurface,
                              ),
                              title: Text(
                                '编辑',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _navigateToEditGroup(group);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline),
                              title: const Text('删除'),
                              textColor: Colors.red,
                              iconColor: Colors.red,
                              onTap: () {
                                Navigator.pop(context);
                                _deleteGroup(group);
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.upload_file,
                                color: theme.colorScheme.onSurface,
                              ),
                              title: Text(
                                '导出群聊',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '导出为JSON文件',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _exportGroup(group);
                              },
                            ),
                            const SizedBox(height: 8),
                            SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: theme.colorScheme.surface,
                                    foregroundColor: theme.colorScheme.primary,
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  child: const Text('取消'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        _groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '还没有群聊',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _navigateToCreateGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('创建群聊'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _groups.length,
                itemBuilder: (context, index) =>
                    _buildGroupCard(_groups[index]),
              ),
        if (_groups.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _navigateToCreateGroup,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}
