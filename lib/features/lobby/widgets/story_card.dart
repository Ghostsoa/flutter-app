import 'package:flutter/material.dart';
import '../../../data/models/hall_item.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/network/api/role_play_api.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../data/models/story.dart';
import '../../../data/local/shared_prefs/story_storage.dart';

class StoryCardViewModel extends ChangeNotifier {
  final String? imageUrl;
  final Map<String, Uint8List> _imageCache;
  bool _isLoading = false;
  Uint8List? _imageData;
  String? _error;

  bool get isLoading => _isLoading;
  Uint8List? get imageData => _imageData;
  String? get error => _error;

  StoryCardViewModel(this.imageUrl, this._imageCache) {
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

class StoryCard extends StatefulWidget {
  final HallItem item;
  final VoidCallback? onTap;

  // 静态缓存
  static final Map<String, Uint8List> _imageCache = {};

  const StoryCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  late final StoryCardViewModel _viewModel;
  bool _importing = false;
  late final AnimationController _dotsAnimationController;
  late final List<Animation<double>> _dotsAnimations;

  @override
  void initState() {
    super.initState();
    _viewModel = StoryCardViewModel(
      widget.item.coverImage,
      StoryCard._imageCache,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '导入中',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Future<void> _importStory() async {
    if (_importing) return;

    setState(() => _importing = true);
    Navigator.pop(context); // 先关闭确认对话框

    // 显示加载对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLoadingDots(),
          ],
        ),
      ),
    );

    try {
      // 1. 获取故事配置
      final api = await RolePlayApi.getInstance();
      final configResponse = await api.getImageBytes(widget.item.configUrl);
      final configData = json.decode(utf8.decode(configResponse));

      // 2. 获取存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final storiesDir = path.join(appDir.path, 'stories');
      final dir = Directory(storiesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 3. 创建故事对象并保存
      final story = await Story.fromExportJson(configData, storiesDir);
      final storage = await StoryStorage.init();
      await storage.saveStory(story);

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('故事【${widget.item.name}】导入成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导入故事'),
            content: Text('是否将故事【${widget.item.name}】导入到本地？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _importing
                    ? null
                    : () {
                        _importStory();
                      },
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
          // 故事封面（大圆角矩形）
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
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
                            color: theme.colorScheme.primary,
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
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '加载失败',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.error,
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
                          Icons.auto_stories_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
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
                          style: theme.textTheme.titleMedium?.copyWith(
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
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 12,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '故事',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onTertiaryContainer,
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.authorName.length > 3
                            ? '${widget.item.authorName.substring(0, 3)}...'
                            : widget.item.authorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(widget.item.updatedAt, locale: 'zh'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
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
