import 'package:flutter/material.dart';
import 'dart:io';

class CharacterCard extends StatelessWidget {
  final String name;
  final String description;
  final String? avatarUrl;
  final List<String> tags;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onTap;

  const CharacterCard({
    super.key,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.tags,
    this.onEdit,
    this.onDelete,
    this.onExport,
    this.onTap,
  });

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),

            // 菜单项
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
                onEdit?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.upload_file,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                '导出角色',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '导出为JSON文件',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onExport?.call();
              },
            ),

            // 底部取消按钮
            const SizedBox(height: 8),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 0.75,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景图或渐变
              if (avatarUrl != null)
                avatarUrl!.startsWith('/')
                    ? Image.file(
                        File(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                      )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              // 渐变遮罩
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // 名字
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    onPressed: () => _showMoreMenu(context),
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
      ),
    );
  }
}
