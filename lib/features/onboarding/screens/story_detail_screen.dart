import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../data/models/story.dart';
import '../../story_roleplay/screens/roleplay_screen.dart';
import '../../../data/local/shared_prefs/story_message_storage.dart';
import '../../../data/local/shared_prefs/story_state_storage.dart';
import '../../../data/local/shared_prefs/story_message_ui_storage.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({
    super.key,
    required this.story,
  });

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _hasExistingChat = false;

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _scrollController.addListener(() {
      final progress = _scrollController.offset / 200;
      setState(() {
        _scrollProgress = progress.clamp(0.0, 1.0);
      });
    });
    _checkExistingChat();
  }

  Future<void> _checkExistingChat() async {
    final messageStorage = await StoryMessageStorage.init();
    final messages = await messageStorage.getMessages(widget.story.id);
    setState(() {
      _hasExistingChat = messages.isNotEmpty;
    });
  }

  Future<void> _resetChat() async {
    final messageStorage = await StoryMessageStorage.init();
    final messageUIStorage = await StoryMessageUIStorage.init();
    final stateStorage = await StoryStateStorage.init();

    await messageStorage.deleteMessages(widget.story.id);
    await messageUIStorage.deleteMessages(widget.story.id);
    await stateStorage.deleteState(widget.story.id);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RoleplayScreen(
          story: widget.story,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        maintainState: true,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
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

  Widget _buildContentSection({
    required String title,
    required String content,
    Color? accentColor,
  }) {
    IconData getIconForTitle(String title) {
      switch (title) {
        case '开场白':
          return Icons.chat_bubble_outline_rounded;
        case '故事设定':
          return Icons.auto_stories_outlined;
        default:
          return Icons.article_outlined;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (accentColor ?? Colors.white).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getIconForTitle(title),
                    color: accentColor ?? Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.story.categoryId);
    final categoryTitle = _getCategoryTitle(widget.story.categoryId);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(_scrollProgress * 0.8),
        elevation: _scrollProgress * 4,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _scrollProgress < 0.5
                  ? Colors.black.withOpacity(0.5)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AnimatedOpacity(
          opacity: _scrollProgress,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.story.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 背景图
          if (widget.story.backgroundImagePath != null)
            Positioned.fill(
              child: Image.file(
                File(widget.story.backgroundImagePath!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                opacity: const AlwaysStoppedAnimation(0.7),
              ),
            ),
          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 0.8],
                ),
              ),
            ),
          ),
          // 内容
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // 封面图和标题区域
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 封面图
                            if (widget.story.coverImagePath != null)
                              Hero(
                                tag: 'story_cover_${widget.story.id}',
                                child: Container(
                                  width: 140,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.file(
                                    File(widget.story.coverImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 24),
                            // 标题和分类信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.story.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              categoryColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color:
                                                categoryColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          categoryTitle,
                                          style: TextStyle(
                                            color: categoryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 400),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A1F25),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        '故事简介',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            color:
                                                                Colors.white70),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: double.infinity,
                                                  height: 1,
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Text(
                                                    widget.story.description,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white
                                                          .withOpacity(0.85),
                                                      height: 1.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      widget.story.description,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                        height: 1.6,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 开场白
                      _buildContentSection(
                        title: '开场白',
                        content: widget.story.opening,
                        accentColor: categoryColor,
                      ),
                      // 故事设定
                      _buildContentSection(
                        title: '故事设定',
                        content: widget.story.settings,
                        accentColor: categoryColor,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // 开始对话按钮
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasExistingChat)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FloatingActionButton.extended(
                    heroTag: 'reset_button',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            '重新开始',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            '确定要重新开始吗？这将删除所有当前的对话记录。',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _resetChat();
                              },
                              child: const Text(
                                '确定',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    elevation: 0,
                    highlightElevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1,
                      ),
                    ),
                    label: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '重新开始',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'start_button',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          RoleplayScreen(
                        story: widget.story,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                      maintainState: true,
                    ),
                  );
                },
                backgroundColor: categoryColor,
                elevation: 8,
                highlightElevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '开始对话',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
