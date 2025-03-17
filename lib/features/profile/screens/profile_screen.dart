import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/network/api/wallet_api.dart';
import '../../../core/utils/logger.dart';
import '../widgets/transaction_history_sheet.dart';
import '../../../data/models/user.dart';
import '../../../core/theme/theme_provider.dart';
import '../../settings/screens/voice_setting_screen.dart';
import '../../../core/network/api/card_key_api.dart';
import '../../../core/network/api/version_api.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../features/support/screens/support_screen.dart';

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
  final _cardKeyApi = CardKeyApi();
  final _versionApi = VersionApi();
  bool _isRedeeming = false;
  String _currentVersion = '1.0.0'; // 从pubspec.yaml中的版本号
  double? _latestVersion;
  bool _hasNewVersion = false;

  @override
  void initState() {
    super.initState();
    _initWalletApi();
    _initApi();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    if (!mounted) return;

    try {
      // 获取当前版本号
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() => _currentVersion = packageInfo.version);

      await _versionApi.init();
      final versionInfo = await _versionApi.getVersion().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('版本检查超时');
        },
      );

      if (!mounted) return;

      setState(() {
        _latestVersion = versionInfo.latestVersion;
        _hasNewVersion =
            _compareVersions(_currentVersion, versionInfo.latestVersion);
      });
    } catch (e) {
      Logger.error('检查版本失败', error: e);
      // 版本检查失败时，不显示更新提示
      if (mounted) {
        setState(() {
          _hasNewVersion = false;
        });
      }
    }
  }

  bool _compareVersions(String currentVersion, double targetVersion) {
    try {
      final parts = currentVersion.split('.');
      if (parts.length >= 2) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);

        // 将目标版本转换为字符串，然后分割
        final targetParts = targetVersion.toString().split('.');
        final targetMajor = int.parse(targetParts[0]);
        final targetMinor =
            targetParts.length > 1 ? int.parse(targetParts[1]) : 0;

        if (major < targetMajor) return true;
        if (major > targetMajor) return false;
        return minor < targetMinor;
      }
      return false;
    } catch (e) {
      Logger.error('版本号比较失败', error: e);
      return false;
    }
  }

  Future<void> _handleUpdate() async {
    final url = Platform.isAndroid
        ? 'https://ai.xiaoyi.live/%E7%BD%91%E6%87%BF%E4%BA%91AI.apk'
        : 'https://ai.xiaoyi.live/%E7%BD%91%E6%87%BF%E4%BA%91AI.ipa';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开下载链接')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开下载链接失败：$e')),
        );
      }
    }
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
        title: const Text('官方讨论与反馈'),
        content: const Text('即将跳转到官方QQ群，是否继续？'),
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

    const url =
        'http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=305f7JRO_ndFjz6Q-ZmLWj3AyeaROspn&authKey=E8yGMbhHyYkC';
    try {
      Logger.info('正在跳转官方QQ群：$url');
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('跳转失败')),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('跳转失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('跳转失败：$e')),
        );
      }
    }
  }

  Future<void> _initApi() async {
    await _cardKeyApi.init();
  }

  void _showRechargeDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.diamond_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '获取小懿币',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '请输入兑换码',
                  hintText: '例如：a1b2c3d4e5f6g7h8',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            controller.text = data!.text!;
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: _isRedeeming
                            ? null
                            : () async {
                                final key = controller.text.trim();
                                if (key.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('提示'),
                                        ],
                                      ),
                                      content: const Text('请输入兑换码'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isRedeeming = true);
                                try {
                                  await _cardKeyApi.redeemCardKey(key);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('成功'),
                                          ],
                                        ),
                                        content: const Text('兑换成功'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      ),
                                    );
                                    // 刷新余额
                                    _refreshBalance();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('兑换失败'),
                                          ],
                                        ),
                                        content: Text(e.toString()),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isRedeeming = false);
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isRedeeming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('兑换'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '* 兑换码仅能使用一次，请勿重复使用',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              _buildRechargeOption(
                context,
                icon: Icons.favorite_outline,
                title: '赞助获取',
                subtitle: '通过赞助获得小懿币',
                onTap: () async {
                  const url = 'https://h5c.fakamiao.top/shopDetail/ayLoyH';
                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                const Text('错误'),
                              ],
                            ),
                            content: const Text('无法打开赞助链接'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              const Text('错误'),
                            ],
                          ),
                          content: Text('打开赞助链接失败：$e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildRechargeOption(
                context,
                icon: Icons.card_giftcard_outlined,
                title: '获取兑换码',
                subtitle: '通过兑换码获得小懿币',
                onTap: () async {
                  const url = 'https://shop.xiaoman.top//links/4D1256ED';
                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                const Text('错误'),
                              ],
                            ),
                            content: const Text('无法打开链接'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              const Text('错误'),
                            ],
                          ),
                          content: Text('打开链接失败：$e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '* 兑换遇到问题请联系客服',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRechargeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildUserInfoCard(theme, user),
          if (_hasNewVersion) ...[
            const SizedBox(height: 20),
            _buildUpdateCard(theme),
          ],
          const SizedBox(height: 20),
          _buildWalletCard(theme),
          const SizedBox(height: 20),
          ..._buildActionItems(theme),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, User? user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user?.username ?? '未登录',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hasNewVersion
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v$_currentVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: _hasNewVersion
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_hasNewVersion) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.new_releases,
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 4),
              Text(
                user!.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.id.toString() ?? 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(user!.createdAt),
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard(ThemeData theme) {
    if (!_hasNewVersion) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: theme.colorScheme.errorContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.system_update,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '发现新版本 v${_latestVersion?.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击更新获取最新版本',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onErrorContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _handleUpdate,
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('更新'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.diamond_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '小懿币',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: theme.colorScheme.primary,
                    ),
              onPressed: _isRefreshing ? null : _refreshBalance,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionItems(ThemeData theme) {
    final themeProvider = ThemeProvider();
    return [
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildActionTile(
              theme,
              icon: Icons.diamond_outlined,
              title: '获取小懿币',
              subtitle: '赞助或使用兑换码',
              onTap: _showRechargeDialog,
            ),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
            _buildActionTile(
              theme,
              icon: Icons.receipt_long,
              title: '最近消耗记录',
              subtitle: '查看消耗明细',
              onTap: _showTransactionHistory,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildActionTile(
              theme,
              icon: Icons.support_agent_outlined,
              title: '智能AI客服',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SupportScreen(),
                ));
              },
            ),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
            _buildActionTile(
              theme,
              icon: Icons.help_outline,
              title: '官方讨论与反馈',
              onTap: _showHelpDialog,
            ),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
            _buildActionTile(
              theme,
              icon: Icons.record_voice_over_outlined,
              title: '语音设置',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceSettingScreen(),
                  ),
                );
              },
            ),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
            _buildActionTile(
              theme,
              icon: Icons.palette_outlined,
              title: '主题颜色',
              onTap: () => _showThemeColorPicker(theme),
            ),
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
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
            Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
            _buildActionTile(
              theme,
              icon: Icons.info_outline,
              title: '关于',
              onTap: _showAboutDialog,
            ),
          ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: theme.colorScheme.primary.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showThemeColorPicker(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildColorOption(Colors.blue, '默认蓝', theme),
              _buildColorOption(const Color(0xFF80CBC4), '薄荷绿', theme),
              _buildColorOption(const Color(0xFFFFB74D), '活力橙', theme),
              _buildColorOption(const Color(0xFFFF8A80), '珊瑚红', theme),
              _buildColorOption(const Color(0xFF9575CD), '梦幻紫', theme),
              _buildColorOption(const Color(0xFF4CAF50), '自然绿', theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, String label, ThemeData theme) {
    final provider = ThemeProvider();
    final isSelected = color.value == provider.themeColor.value;

    return GestureDetector(
      onTap: () {
        provider.setThemeColor(color);
        Navigator.of(context).pop();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
