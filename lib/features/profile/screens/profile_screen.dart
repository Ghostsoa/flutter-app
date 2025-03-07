import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/network/api/wallet_api.dart';
import '../../../core/utils/logger.dart';
import '../widgets/transaction_history_sheet.dart';
import '../../../data/models/user.dart';
import '../../../core/theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authController = AuthController();
  bool _isRefreshing = false;
  WalletApi? _walletApi;
  double _balance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWalletApi();
  }

  Future<void> _initWalletApi() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      Logger.info('初始化钱包API');
      _walletApi = await WalletApi.getInstance();

      // 添加短暂延迟，确保 DioClient 完全初始化
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      await _refreshBalance();
    } catch (e, stackTrace) {
      Logger.error('钱包API初始化失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshBalance() async {
    if (_isRefreshing || _walletApi == null) return;
    setState(() => _isRefreshing = true);

    try {
      Logger.info('获取小懿币');
      await Future.delayed(const Duration(milliseconds: 50)); // 添加短暂延迟
      final balance = await _walletApi!.getBalance();
      if (mounted) {
        setState(() {
          _balance = balance;
          _isRefreshing = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('获取小懿币', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _showTransactionHistory() async {
    if (!mounted || _walletApi == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => TransactionHistorySheet(
          walletApi: _walletApi!,
        ),
      ),
    );
  }

  Future<void> _showAboutDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('版本：1.0'),
              SizedBox(height: 16),
              Text(
                '免责声明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. 本服务仅作为AI大语言模型的中转服务，所有生成的内容均由AI模型自动生成。',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                '2. 用户在使用本服务时必须遵守所有适用的法律法规。严禁使用本服务：',
                style: TextStyle(fontSize: 13),
              ),
              Padding(
                padding: EdgeInsets.only(left: 12, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· 从事任何违法违规活动', style: TextStyle(fontSize: 13)),
                    Text('· 生成违法、暴力、色情等不当内容', style: TextStyle(fontSize: 13)),
                    Text('· 侵犯他人知识产权或其他合法权益', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '3. 用户对使用本服务的一切行为及结果承担全部责任。',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                '4. 本服务不对AI生成内容的准确性、完整性、适用性提供任何明示或暗示的保证。',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                '5. 我们保留在发现违规行为时终止服务的权利。',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelpDialog() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助与反馈'),
        content: const Text('即将跳转到官网页面，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    const url = 'https://ai.xiaoyi.live';
    try {
      Logger.info('正在打开帮助页面：$url');
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开帮助页面')),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('打开帮助页面失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开帮助页面失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authController.currentUser;

    final profileItems = [
      _buildUserInfoCard(theme, user),
      const SizedBox(height: 24),
      _buildWalletCard(theme),
      const SizedBox(height: 24),
      ..._buildActionItems(theme),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authController.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: profileItems.length,
        itemBuilder: (context, index) => profileItems[index],
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? '未登录',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.id.toString() ?? 'N/A',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (user?.createdAt != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注册时间',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy-MM-dd').format(
                              DateTime.parse(user!.createdAt),
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '小懿币',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Text(
                      _balance.toStringAsFixed(2),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isRefreshing ? null : _refreshBalance,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionItems(ThemeData theme) {
    final themeProvider = ThemeProvider();
    return [
      _buildActionTile(
        theme,
        icon: Icons.account_balance_wallet,
        title: '赞助我们',
        onTap: () async {
          const url = 'https://h5c.fakamiao.top/shopDetail/ayLoyH';
          try {
            Logger.info('正在打开充值链接：$url');
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开充值页面')),
                );
              }
            }
          } catch (e, stackTrace) {
            Logger.error('打开充值链接失败', error: e, stackTrace: stackTrace);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('打开充值页面失败：$e')),
              );
            }
          }
        },
      ),
      const Divider(indent: 72),
      _buildActionTile(
        theme,
        icon: Icons.receipt_long,
        title: '最近消耗记录',
        subtitle: '查看消耗明细',
        onTap: _showTransactionHistory,
      ),
      const Divider(indent: 72),
      _buildActionTile(
        theme,
        icon: Icons.help_outline,
        title: '帮助与反馈',
        onTap: _showHelpDialog,
      ),
      const Divider(indent: 72),
      _buildActionTile(
        theme,
        icon: Icons.info_outline,
        title: '关于',
        onTap: _showAboutDialog,
      ),
      const Divider(indent: 72),
      _buildActionTile(
        theme,
        icon: Icons.dark_mode,
        title: '深色模式',
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (bool value) async {
            await themeProvider.toggleTheme();
          },
        ),
      ),
    ];
  }

  Widget _buildActionTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
