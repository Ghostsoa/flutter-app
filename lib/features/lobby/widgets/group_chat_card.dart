import 'package:flutter/material.dart';
import '../../../data/models/hall_item.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/network/api/role_play_api.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/group_chat_repository.dart';
import '../../../data/models/group_chat.dart';

class GroupChatCardViewModel extends ChangeNotifier {
  final String? imageUrl;
  final Map<String, Uint8List> _imageCache;
  bool _isLoading = false;
  Uint8List? _imageData;
  String? _error;

  bool get isLoading => _isLoading;
  Uint8List? get imageData => _imageData;
  String? get error => _error;

  GroupChatCardViewModel(this.imageUrl, this._imageCache) {
    if (imageUrl != null) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (imageUrl == null) return;

    if (_imageCache.containsKey(imageUrl)) {
      _imageData = _imageCache[imageUrl];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await RolePlayApi.getInstance();
      final bytes = await api.getImageBytes(imageUrl!);
      _imageCache[imageUrl!] = bytes;
      _imageData = bytes;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class GroupChatCard extends StatefulWidget {
  final HallItem item;
  final VoidCallback? onTap;

  // 静态缓存
  static final Map<String, Uint8List> _imageCache = {};

  const GroupChatCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<GroupChatCard> createState() => _GroupChatCardState();
}

class _GroupChatCardState extends State<GroupChatCard>
    with SingleTickerProviderStateMixin {
  late final GroupChatCardViewModel _viewModel;
  bool _importing = false;
  late final AnimationController _dotsAnimationController;
  late final List<Animation<double>> _dotsAnimations;

  @override
  void initState() {
    super.initState();
    _viewModel = GroupChatCardViewModel(
      widget.item.coverImage,
      GroupChatCard._imageCache,
    );

    // 初始化动画控制器
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

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
    _viewModel.dispose();
    _dotsAnimationController.dispose();
    super.dispose();
  }

  Widget _buildLoadingDots() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '导入中',
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

  Future<void> _importGroupChat() async {
    if (_importing) return;

    setState(() => _importing = true);
    Navigator.pop(context); // 先关闭确认对话框

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildLoadingDots(),
      ),
    );

    try {
      // 1. 获取群聊配置
      final api = await RolePlayApi.getInstance();
      final configResponse = await api.getImageBytes(widget.item.configUrl);
      final configData = json.decode(utf8.decode(configResponse));

      // 2. 生成新的ID
      configData['id'] = const Uuid().v4();

      // 3. 处理角色头像数据
      if (configData['roles'] != null) {
        final roles = configData['roles'] as List;
        for (final role in roles) {
          if (role['avatarData'] != null) {
            role['avatarUrl'] = role['avatarData'];
          }
        }
      }

      // 4. 创建群聊对象并保存
      final repository = await GroupChatRepository.create();
      final groupChat = GroupChat.fromJson(configData);
      await repository.saveGroupChat(groupChat);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('群聊【${groupChat.name}】导入成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导入群聊'),
            content: Text('是否将群聊【${widget.item.name}】导入到本地？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _importing ? null : _importGroupChat,
                child: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('导入'),
              ),
            ],
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 群聊封面（圆角矩形）
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      if (_viewModel.isLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }

                      if (_viewModel.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 32,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '加载失败',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_viewModel.imageData != null) {
                        return Image.memory(
                          _viewModel.imageData!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }

                      return Center(
                        child: Icon(
                          Icons.groups_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  // 角色数量标签
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.item.roleCount}个角色',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和标签
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '群聊',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 简介
                  Text(
                    widget.item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          height: 1.5,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // 作者和时间
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.authorName.length > 3
                            ? '${widget.item.authorName.substring(0, 3)}...'
                            : widget.item.authorName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(widget.item.updatedAt, locale: 'zh'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
