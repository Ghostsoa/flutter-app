import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../widgets/story_card.dart';
import 'story_edit_screen.dart';
import 'story_detail_screen.dart';
import '../../../data/models/story.dart';
import '../../../data/local/shared_prefs/story_storage.dart';
import '../../../data/local/shared_prefs/story_message_storage.dart';
import '../../../data/local/shared_prefs/story_message_ui_storage.dart';
import '../../../data/local/shared_prefs/story_state_storage.dart';
import '../../../core/utils/story_export_util.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late StoryStorage _storage;
  List<Story> _stories = [];
  bool _isLoading = true;
  PageController _pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 0,
  );
  int _currentPage = 0;

  // 分类数据
  final List<CategoryData> _categories = [
    CategoryData(
      id: 'all',
      title: '全部',
      color: const Color(0xFF64748B),
    ),
    CategoryData(
      id: 'xiuxian',
      title: '修仙',
      color: const Color(0xFFE056FD),
    ),
    CategoryData(
      id: 'thriller',
      title: '惊悚',
      color: const Color(0xFFFF7675),
    ),
    CategoryData(
      id: 'ancient',
      title: '古风',
      color: const Color(0xFF74B9FF),
    ),
    CategoryData(
      id: 'urban',
      title: '都市',
      color: const Color(0xFF00B894),
    ),
  ];

  String _selectedCategoryId = 'all';

  List<Story> get _filteredStories {
    if (_selectedCategoryId == 'all') {
      return _stories;
    }
    return _stories
        .where((story) => story.categoryId == _selectedCategoryId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _initStorage();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (!mounted) return;
    final page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _initStorage() async {
    _storage = await StoryStorage.init();
    await _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storage.getStories();
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载故事失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStory(Story story) async {
    try {
      // 删除故事数据
      await _storage.deleteStory(story.id);

      // 删除对话记录
      final messageStorage = await StoryMessageStorage.init();
      await messageStorage.deleteMessages(story.id);

      // 删除UI消息记录
      final messageUIStorage = await StoryMessageUIStorage.init();
      await messageUIStorage.deleteMessages(story.id);

      // 删除故事状态
      final stateStorage = await StoryStateStorage.init();
      await stateStorage.deleteState(story.id);

      // 删除相关图片文件
      if (story.coverImagePath != null) {
        final coverFile = File(story.coverImagePath!);
        if (await coverFile.exists()) {
          await coverFile.delete();
        }
      }
      if (story.backgroundImagePath != null) {
        final backgroundFile = File(story.backgroundImagePath!);
        if (await backgroundFile.exists()) {
          await backgroundFile.delete();
        }
      }

      // 重新加载故事列表
      await _loadStories();
    } catch (e) {
      debugPrint('删除故事失败: $e');
    }
  }

  Future<void> _handleImport() async {
    try {
      setState(() => _isLoading = true);
      final importedStories = await StoryExportUtil.importStories(_storage);
      if (importedStories.isNotEmpty) {
        await _loadStories();
      }
    } catch (e) {
      debugPrint('导入故事失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _restoreScreen();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  void _restoreScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1F25),
                const Color(0xFF141619),
                const Color(0xFF0D0E10),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.12), // 顶部光源
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1A1F25).withOpacity(0.3),
                    const Color(0xFF1A1F25).withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "探索",
                                  style: TextStyle(
                                    fontSize: 28,
                                    height: 1.1,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "故事",
                                  style: TextStyle(
                                    fontSize: 28,
                                    height: 1.1,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 添加按钮
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StoryEditScreen(),
                                    fullscreenDialog: true,
                                  ),
                                )
                                    .then((saved) {
                                  if (saved == true) {
                                    _loadStories();
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '添加',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 导入按钮
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _isLoading ? null : _handleImport,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '导入',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        "发现属于你的精彩故事",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 分类标签
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category.id == _selectedCategoryId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? category.color.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? category.color
                                      : Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                children: [
                                  if (isSelected) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: category.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    category.title,
                                    style: TextStyle(
                                      color: isSelected
                                          ? category.color
                                          : Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 故事列表
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _filteredStories.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_stories_outlined,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '暂无故事',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: PageView.builder(
                                        controller: _pageController,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: _filteredStories.length,
                                        itemBuilder: (context, index) {
                                          final story = _filteredStories[index];
                                          final isSelected =
                                              index == _currentPage;
                                          double scale = 1.0;
                                          if (_pageController
                                              .position.haveDimensions) {
                                            scale = 1.0 -
                                                ((_currentPage - index).abs() *
                                                    0.15);
                                            scale = scale.clamp(0.85, 1.0);
                                          }
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            transform: Matrix4.identity()
                                              ..scale(scale),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: Colors.black.withOpacity(
                                                  isSelected ? 0.0 : 0.3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: StoryCard(
                                              story: story,
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StoryDetailScreen(
                                                      story: story,
                                                    ),
                                                  ),
                                                );
                                              },
                                              onDelete: _deleteStory,
                                              onEdit: () => _loadStories(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // 页面指示器
                                    Container(
                                      height: 40,
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          _filteredStories.length,
                                          (index) {
                                            final isSelected =
                                                index == _currentPage;
                                            return TweenAnimationBuilder(
                                              tween: Tween<double>(
                                                begin: isSelected ? 0.0 : 1.0,
                                                end: isSelected ? 1.0 : 0.0,
                                              ),
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              builder: (context, double value,
                                                  child) {
                                                return Container(
                                                  width: isSelected ? 20 : 8,
                                                  height: 8,
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 4),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: isSelected
                                                        ? Colors.white
                                                            .withOpacity(0.9)
                                                        : Colors.white
                                                            .withOpacity(0.3),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.2),
                                                              blurRadius: 4,
                                                              spreadRadius: 1,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                    // 退出按钮
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(
                        bottom: 24,
                        top: 16,
                      ),
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.exit_to_app,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          '退出探索',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryData {
  final String id;
  final String title;
  final Color color;

  CategoryData({
    required this.id,
    required this.title,
    required this.color,
  });
}

class StoryData {
  final String title;
  final String description;
  final String imageUrl;
  final String categoryId;

  StoryData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
  });
}
