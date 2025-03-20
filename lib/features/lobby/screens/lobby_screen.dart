import 'package:flutter/material.dart';
import '../widgets/single_character_card.dart';
import '../widgets/group_chat_card.dart';
import '../widgets/story_card.dart';
import '../../../data/models/hall_item.dart';
import '../../../core/network/api/role_play_api.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pull_to_refresh/pull_to_refresh.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _showTitleNotifier = ValueNotifier<bool>(false);
  final _selectedTypeNotifier = ValueNotifier<String?>(null);
  final _isMyItemsNotifier = ValueNotifier<bool>(false);
  final _refreshController = RefreshController();
  final _searchController = TextEditingController();
  final _items = <HallItem>[];
  String _searchQuery = '';
  static const _pageSize = 5;
  late final TabController _tabController;
  RolePlayApi? _api;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  Future<void>? _loadingFuture;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
    timeago.setDefaultLocale('zh');
    _scrollController.addListener(_handleScroll);
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    setState(() {
      _isLoading = true;
    });
    _loadingFuture = _initApi();
  }

  Future<void> _initApi() async {
    _api = await RolePlayApi.getInstance();
    await _loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && !_showTitleNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTitleNotifier.value = true;
      });
    } else if (_scrollController.offset <= 100 && _showTitleNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTitleNotifier.value = false;
      });
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _isLoading = true;
      });
      switch (_tabController.index) {
        case 0:
          _selectedTypeNotifier.value = null;
          _isMyItemsNotifier.value = false;
          break;
        case 1:
          _selectedTypeNotifier.value = 'character';
          _isMyItemsNotifier.value = false;
          break;
        case 2:
          _selectedTypeNotifier.value = 'group_chat';
          _isMyItemsNotifier.value = false;
          break;
        case 3:
          _selectedTypeNotifier.value = 'story';
          _isMyItemsNotifier.value = false;
          break;
        case 4:
          _isMyItemsNotifier.value = true;
          break;
      }
      _onRefresh().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });
    _currentPage = 1;
    _hasMore = true;
    _items.clear();
    await _loadData();
    _refreshController.refreshCompleted();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }
    await _loadData();
    _refreshController.loadComplete();
  }

  Future<void> _loadData() async {
    try {
      final response = _isMyItemsNotifier.value
          ? await _api!.getMyItems(
              page: _currentPage,
              pageSize: _pageSize,
              type: _selectedTypeNotifier.value,
              query: _searchQuery.isNotEmpty ? _searchQuery : null,
            )
          : await _api!.getHallItems(
              page: _currentPage,
              pageSize: _pageSize,
              type: _selectedTypeNotifier.value,
              query: _searchQuery.isNotEmpty ? _searchQuery : null,
            );

      if (mounted) {
        setState(() {
          _items.addAll(response.list);
          _hasMore = _currentPage < response.pages;
          if (_hasMore) {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
      _refreshController.loadFailed();
    }
  }

  Future<void> _handleDelete(HallItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除【${item.name}】吗？此操作不可恢复。'),
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
        await _api!.deleteItem(item.id);
        _onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showTitleNotifier.dispose();
    _selectedTypeNotifier.dispose();
    _isMyItemsNotifier.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            centerTitle: true,
            title: ValueListenableBuilder<bool>(
              valueListenable: _showTitleNotifier,
              builder: (context, showTitle, _) {
                return AnimatedOpacity(
                  opacity: showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Text('大厅'),
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '发现角色和故事',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '探索精彩对话，发现有趣角色',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.shadow.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '搜索卡名或作者...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 15,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                        _onRefresh();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            cursorColor: theme.colorScheme.primary,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _onRefresh();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('全部'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 16),
                      SizedBox(width: 4),
                      Text('单人'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('群聊'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('故事'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_special_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('我的'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: FutureBuilder(
          future: _loadingFuture,
          builder: (context, snapshot) {
            if (_isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在加载...',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: true,
                  header: const WaterDropHeader(
                    complete: Text('刷新完成'),
                    failed: Text('刷新失败'),
                    waterDropColor: Colors.blue,
                  ),
                  footer: CustomFooter(
                    loadStyle: LoadStyle.ShowWhenLoading,
                    height: 40,
                    builder: (context, mode) {
                      Widget? body;
                      if (mode == LoadStatus.idle) {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "上拉加载更多",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      } else if (mode == LoadStatus.loading) {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "正在加载...",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      } else if (mode == LoadStatus.failed) {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 15,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "加载失败，点击重试",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        );
                      } else if (mode == LoadStatus.canLoading) {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "松手加载更多",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      } else {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 15,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "已经到底啦",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      }
                      return SizedBox(
                        height: 40,
                        child: Center(child: body),
                      );
                    },
                  ),
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: _items.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无内容',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _items.length - 1 ? 16 : 0,
                            ),
                            child: Stack(
                              children: [
                                _buildCard(_items[index]),
                                if (_isMyItemsNotifier.value)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Material(
                                      elevation: 4,
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () =>
                                            _handleDelete(_items[index]),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '删除',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_isLoading && _items.isNotEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(HallItem item) {
    return switch (item.type) {
      'character' => SingleCharacterCard(
          key: ValueKey('character_${item.id}'),
          item: item,
        ),
      'group_chat' => GroupChatCard(
          key: ValueKey('group_chat_${item.id}'),
          item: item,
        ),
      'story' => StoryCard(
          key: ValueKey('story_${item.id}'),
          item: item,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
