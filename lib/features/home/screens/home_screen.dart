import 'package:flutter/material.dart';
import '../../../core/network/api/lottery_api.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/announcement.dart';
import '../widgets/daily_check_in_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/winners_list.dart';
import 'announcement_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LotteryApi _lotteryApi;
  bool _isSigningIn = false;
  bool _isDrawing = false;
  bool _isLoading = true;
  bool _hasNewAnnouncement = false;

  @override
  void initState() {
    super.initState();
    _initApi();
  }

  Future<void> _initApi() async {
    try {
      _lotteryApi = await LotteryApi.getInstance();
      await _checkAnnouncement();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAnnouncement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = prefs.getInt('current_announcement_id');

      final result = await _lotteryApi.getLatestAnnouncement(
        currentId: currentId,
      );

      if (result.needUpdate && result.announcement != null) {
        if (mounted) {
          setState(() => _hasNewAnnouncement = true);
          // 保存最新公告ID
          await prefs.setInt(
              'current_announcement_id', result.announcement!.id);
          // 显示新公告弹窗
          _showAnnouncementDialog(result.announcement!);
        }
      }
    } catch (e, stackTrace) {
      Logger.error(
        '检查公告失败',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _showAnnouncementDialog(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text(announcement.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(announcement.content),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openAnnouncementScreen();
            },
            child: const Text('查看更多'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      await _lotteryApi.signInDaily();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('签到成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().contains('今日已签到') ? '今日已签到' : '签到失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleDraw() async {
    if (_isDrawing) return;
    setState(() => _isDrawing = true);

    try {
      final result = await _lotteryApi.drawLottery();
      if (mounted) {
        final amount = result['amount'] as int; // 从返回的 Map 中获取 amount
        final isProfit = amount > 0; // 大于0就是盈利（后台已计算成本）

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProfit ? '恭喜获得 $amount 小懿币！' : '再接再厉，本次亏损 ${amount.abs()} 小懿币',
            ),
            backgroundColor: isProfit ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().contains('抽奖次数已用完') ? '抽奖次数已用完' : '抽奖失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDrawing = false);
      }
    }
  }

  void _openAnnouncementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementScreen(),
      ),
    ).then((_) {
      setState(() => _hasNewAnnouncement = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('首页'),
        actions: [
          IconButton(
            icon: Badge(
              label: _hasNewAnnouncement ? const Text('1') : null,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: _openAnnouncementScreen,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 签到卡片
          DailyCheckInCard(
            onTap: _isSigningIn ? null : _handleSignIn,
            isLoading: _isSigningIn,
          ),
          const SizedBox(height: 16),

          // 幸运抽奖卡片
          FeatureCard(
            title: '幸运抽奖',
            icon: Icons.star,
            color: theme.colorScheme.secondary,
            onTap: _isDrawing ? null : _handleDraw,
            isLoading: _isDrawing,
            showInfo: true,
            infoText: '抽奖说明：抽奖仅作为娱乐功能，切勿上头盲目抽奖\n\n'
                '奖池概率：\n'
                '520小懿币：0.5%\n'
                '100小懿币：1.5%\n'
                '50小懿币：8%\n'
                '20小懿币：20%\n'
                '10小懿币：40%\n'
                '5小懿币：20%\n'
                '1保底小懿币：10%\n\n'
                '每次抽奖消耗10小懿币',
          ),
          const SizedBox(height: 16),

          // 中奖榜单
          WinnersList(lotteryApi: LotteryApi.getInstance()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
