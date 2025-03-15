import 'package:flutter/material.dart';
import '../widgets/single_character_card.dart';
import '../widgets/group_chat_card.dart';
import '../widgets/story_card.dart';
import '../../../data/models/hall_item.dart';
import '../../../core/network/api/role_play_api.dart';
import 'package:timeago/timeago.dart' as timeago;

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _scrollController = ScrollController();
  final _showTitleNotifier = ValueNotifier<bool>(false);
  final _selectedTypeNotifier = ValueNotifier<String?>(null);
  final _isLoadingNotifier = ValueNotifier<bool>(false);
  final _hasMoreNotifier = ValueNotifier<bool>(true);
  final _currentPageNotifier = ValueNotifier<int>(1);
  final _itemsNotifier = ValueNotifier<List<HallItem>>([]);
  RolePlayApi? _api;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
    timeago.setDefaultLocale('zh');
    _scrollController.addListener(_handleScroll);
    _initApi();
  }

  Future<void> _initApi() async {
    _api = await RolePlayApi.getInstance();
    await _loadItems(isRefresh: true);
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

    // 检查是否需要加载更多
    if (!_isLoadingNotifier.value && // 确保当前没有在加载
        _hasMoreNotifier.value && // 确保还有更多数据
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMore();
      });
    }
  }

  Future<void> _loadItems({bool isRefresh = false}) async {
    if (_isLoadingNotifier.value || (!_hasMoreNotifier.value && !isRefresh)) {
      return;
    }

    _isLoadingNotifier.value = true;

    try {
      final page = isRefresh ? 1 : _currentPageNotifier.value + 1;
      final response = await _api!.getHallItems(
        page: page,
        pageSize: 5,
        type: _selectedTypeNotifier.value,
      );

      if (mounted) {
        if (isRefresh) {
          _itemsNotifier.value = response.list;
          _currentPageNotifier.value = 1;
        } else {
          final currentItems = _itemsNotifier.value;
          currentItems.addAll(response.list);
          _currentPageNotifier.value = page;
        }

        // 更新是否还有更多数据
        _hasMoreNotifier.value =
            response.list.isNotEmpty && response.page < response.pages;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingNotifier.value && _hasMoreNotifier.value) {
      await _loadItems();
    }
  }

  Future<void> _handleRefresh() async {
    await _loadItems(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showTitleNotifier.dispose();
    _selectedTypeNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasMoreNotifier.dispose();
    _currentPageNotifier.dispose();
    _itemsNotifier.dispose();
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // 分类筛选
            SizedBox(
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<String?>(
                  valueListenable: _selectedTypeNotifier,
                  builder: (context, selectedType, _) {
                    return Row(
                      children: [
                        _buildFilterChip(
                          label: '全部',
                          selected: selectedType == null,
                          onSelected: (selected) {
                            _selectedTypeNotifier.value = null;
                            _loadItems(isRefresh: true);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '单人',
                          icon: Icons.person_outline,
                          selected: selectedType == 'character',
                          onSelected: (selected) {
                            _selectedTypeNotifier.value =
                                selected ? 'character' : null;
                            _loadItems(isRefresh: true);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '群聊',
                          icon: Icons.groups_outlined,
                          selected: selectedType == 'group_chat',
                          onSelected: (selected) {
                            _selectedTypeNotifier.value =
                                selected ? 'group_chat' : null;
                            _loadItems(isRefresh: true);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '故事',
                          icon: Icons.auto_stories_outlined,
                          selected: selectedType == 'story',
                          onSelected: (selected) {
                            _selectedTypeNotifier.value =
                                selected ? 'story' : null;
                            _loadItems(isRefresh: true);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // 列表
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingNotifier,
                  builder: (context, isLoading, _) {
                    return ValueListenableBuilder<List<HallItem>>(
                      valueListenable: _itemsNotifier,
                      builder: (context, items, _) {
                        if (items.isEmpty && !isLoading) {
                          return Center(
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
                          );
                        }

                        return ValueListenableBuilder<bool>(
                          valueListenable: _hasMoreNotifier,
                          builder: (context, hasMore, _) {
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  items.length + (hasMore || isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == items.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final item = items[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < items.length - 1 ? 16 : 0,
                                  ),
                                  child: switch (item.type) {
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
                                  },
                                );
                              },
                            );
                          },
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
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: theme.colorScheme.surfaceVariant,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
