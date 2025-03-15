import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/story_edit_screen.dart';
import '../../../data/models/story.dart';
import '../../../core/utils/story_export_util.dart';
import '../../../core/network/api/role_play_api.dart';
import 'dart:io';

class StoryCard extends StatefulWidget {
  final Story story;
  final VoidCallback onTap;
  final Function(Story) onDelete;
  final VoidCallback onEdit;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  _StoryCardState createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsAnimationController;
  late final List<Animation<double>> _dotsAnimations;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 创建三个点的动画
    _dotsAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotsAnimationController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _dotsAnimationController.dispose();
    super.dispose();
  }

  String _getCategoryTitle(String categoryId) {
    switch (categoryId) {
      case 'xiuxian':
        return '修仙';
      case 'thriller':
        return '惊悚';
      case 'ancient':
        return '古风';
      case 'urban':
        return '都市';
      default:
        return '未知';
    }
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'xiuxian':
        return const Color(0xFFE056FD);
      case 'thriller':
        return const Color(0xFFFF7675);
      case 'ancient':
        return const Color(0xFF74B9FF);
      case 'urban':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.edit_rounded,
                label: '编辑',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => StoryEditScreen(
                        isEditing: true,
                        story: widget.story,
                      ),
                    ),
                  )
                      .then((edited) {
                    if (edited == true) {
                      widget.onEdit();
                    }
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              _buildMenuItem(
                context,
                icon: Icons.share_outlined,
                label: '分享到大厅',
                onTap: () {
                  Navigator.pop(context);
                  _handleShare(context);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              _buildMenuItem(
                context,
                icon: Icons.file_upload_outlined,
                label: '导出',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await StoryExportUtil.exportStory(widget.story);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('导出成功')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('导出失败: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              _buildMenuItem(
                context,
                icon: Icons.delete_outline_rounded,
                label: '删除',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(widget.story);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? Colors.red[400] : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.all(
          Colors.white.withOpacity(0.1),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: color?.withOpacity(0.9),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color?.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    // 显示上传对话框
    if (!context.mounted) return;
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return Dialog(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildLoadingDots(),
        );
      },
    );

    // 启动动画
    _dotsAnimationController.repeat();

    try {
      final api = await RolePlayApi.getInstance();
      final result = await api.uploadStory(widget.story);

      if (!mounted) return;

      // 立即停止动画
      if (_dotsAnimationController.isAnimating) {
        _dotsAnimationController.stop();
        _dotsAnimationController.reset();
      }

      // 关闭对话框
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享成功：${result['message']}')),
      );
    } catch (e) {
      if (!mounted) return;

      // 立即停止动画
      if (_dotsAnimationController.isAnimating) {
        _dotsAnimationController.stop();
        _dotsAnimationController.reset();
      }

      // 关闭对话框
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  Widget _buildLoadingDots() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '上传中',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _dotsAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -4 * _dotsAnimations[index].value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = _getCategoryTitle(widget.story.categoryId);
    final categoryColor = _getCategoryColor(widget.story.categoryId);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: widget.story.coverImagePath != null
                  ? Image.file(
                      File(widget.story.coverImagePath!),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    )
                  : Container(
                      color: Colors.grey[900],
                    ),
            ),
            // 渐变遮罩
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // 内容
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部操作栏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 分类标签
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: categoryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: categoryColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryTitle,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: categoryColor.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 更多操作按钮
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Builder(
                            builder: (context) => GestureDetector(
                              onTapDown: (details) {
                                final button =
                                    context.findRenderObject() as RenderBox;
                                final offset =
                                    button.localToGlobal(Offset.zero);
                                _showMoreMenu(context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '设置',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 底部信息
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.story.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.story.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
