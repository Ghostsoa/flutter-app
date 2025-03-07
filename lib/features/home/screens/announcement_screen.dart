import 'package:flutter/material.dart';
import '../../../core/network/api/lottery_api.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/announcement.dart';
import 'package:intl/intl.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  late final LotteryApi _api;
  final List<Announcement> _announcements = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  static const _pageSize = 20;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initApi();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (currentScroll >= (maxScroll * 0.9)) {
      _loadMore();
    }
  }

  Future<void> _initApi() async {
    try {
      _api = await LotteryApi.getInstance();
      await _loadAnnouncements(refresh: true);
    } catch (e, stackTrace) {
      Logger.error('初始化API失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('初始化失败：$e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _initApi,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAnnouncements({bool refresh = false}) async {
    if (!refresh && (_isLoading || !_hasMore)) return;

    setState(() => _isLoading = true);

    try {
      final page = refresh ? 1 : _currentPage;
      Logger.info('开始加载公告列表', tag: 'Announcement');
      Logger.info('加载参数',
          tag: 'Announcement-Params: ${{
            'page': page,
            'pageSize': _pageSize,
            'currentCount': _announcements.length,
            'isRefresh': refresh,
          }}');

      final result = await _api.getAnnouncementsList(
        page: page,
        pageSize: _pageSize,
      );

      Logger.info('公告列表加载成功', tag: 'Announcement');
      Logger.info('加载结果',
          tag: 'Announcement-Result: ${{
            'total': result.total,
            'itemsCount': result.items.length,
            'page': result.page,
            'pageSize': result.pageSize,
          }}');

      if (mounted) {
        setState(() {
          if (refresh) {
            _announcements.clear();
            _currentPage = 1;
          }

          _announcements.addAll(result.items);
          _hasMore = _announcements.length < result.total;
          if (_hasMore) _currentPage++;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('加载公告列表失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败：$e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () => _loadAnnouncements(refresh: true),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadAnnouncements();
  }

  Future<void> _onRefresh() async {
    await _loadAnnouncements(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('系统公告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAnnouncements(refresh: true),
          ),
        ],
      ),
      body: _isLoading && _announcements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无公告',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _loadAnnouncements(refresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _announcements.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final announcement = _announcements[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      announcement.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MM-dd HH:mm')
                                        .format(announcement.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                announcement.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
