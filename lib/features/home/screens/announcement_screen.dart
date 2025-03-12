import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api/lottery_api.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/announcement.dart';
import 'dart:async';

class AnnouncementScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementScreen({
    super.key,
    required this.announcement,
  });

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
  int _countdown = 3;

  final _scrollController = ScrollController();
  bool _canClose = false;
  bool _showConfirmation = false;

  @override
  void initState() {
    super.initState();
    _initApi();
    _scrollController.addListener(_onScroll);
    _startTimer();
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

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canClose = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleCancel() {
    SystemNavigator.pop(); // 退出应用
  }

  void _handleRead() {
    setState(() {
      _showConfirmation = true;
    });
  }

  void _handleConfirm() {
    Navigator.of(context).pop(true);
  }

  void _handleReread() {
    setState(() {
      _showConfirmation = false;
      _canClose = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '重要公告',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!_canClose)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_countdown',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '秒后可操作',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showConfirmation) ...[
                        const Text(
                          '我已阅读并承诺不向开发者提出公告内容中已通知的各种问题',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _handleReread,
                                child: const Text('重新阅读'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                onPressed: _handleConfirm,
                                child: const Text('确定'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          widget.announcement.content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        if (_canClose) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('取消'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _handleRead,
                                  child: const Text('我已阅读'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
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
