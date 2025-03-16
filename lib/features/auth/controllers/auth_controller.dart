import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/logger.dart';
import '../../../core/network/api/version_api.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  late final AuthRepository _repository;
  late final SharedPreferences _prefs;
  User? _currentUser;
  bool _isLoading = false;
  final bool _isCheckingVersion = false;
  String _currentVersion = '';
  double? _latestVersion;
  bool _hasNewVersion = false;
  bool _needsForceUpdate = false;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  bool get isCheckingVersion => _isCheckingVersion;
  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  bool get hasNewVersion => _hasNewVersion;
  bool get needsForceUpdate => _needsForceUpdate;
  String get currentVersion => _currentVersion;
  double? get latestVersion => _latestVersion;

  AuthController._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      // 初始化基础服务
      _prefs = await SharedPreferences.getInstance();
      _repository = await AuthRepository.create();
      _isInitialized = true;

      // 尝试自动登录
      await _tryAutoLogin();

      // 登录成功后再检查版本
      if (_currentUser != null) {
        await _checkVersion();
      }
    } catch (e, stackTrace) {
      Logger.error('初始化失败', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkVersion() async {
    try {
      // 获取当前版本号
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // 初始化版本API并检查版本
      final versionApi = VersionApi();
      await versionApi.init();
      final versionInfo = await versionApi.getVersion();

      _latestVersion = versionInfo.latestVersion;
      _hasNewVersion =
          _compareVersions(_currentVersion, versionInfo.latestVersion);
      _needsForceUpdate =
          _compareVersions(_currentVersion, versionInfo.minVersion);

      notifyListeners();
    } catch (e) {
      Logger.error('版本检查失败', error: e);
    }
  }

  bool _compareVersions(String currentVersion, double targetVersion) {
    try {
      final parts = currentVersion.split('.');
      if (parts.length >= 2) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final targetMajor = targetVersion.floor();
        final targetMinor = ((targetVersion - targetMajor) * 10).floor();

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

  Future<void> _tryAutoLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 检查是否有保存的账号密码
      final savedEmail = _prefs.getString('saved_email');
      final savedPassword = _prefs.getString('saved_password');
      final rememberMe = _prefs.getBool('remember_me') ?? false;

      if (savedEmail != null && savedPassword != null && rememberMe) {
        Logger.info('尝试使用保存的账号密码登录');
        final (user, _) = await _repository.login(savedEmail, savedPassword);
        _currentUser = user;
        Logger.info('账号密码登录成功');
      }
    } catch (e, stackTrace) {
      Logger.error('自动登录失败', error: e, stackTrace: stackTrace);
      // 清除保存的登录信息
      await _prefs.remove('saved_email');
      await _prefs.remove('saved_password');
      await _prefs.setBool('remember_me', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送验证码
  Future<({bool success, String? message})> sendVerificationCode(
      String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _repository.sendVerificationCode(email);
      return (
        success: true,
        message: response['message'] as String? ?? '验证码已发送'
      );
    } catch (e) {
      return (success: false, message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 注册
  Future<({bool success, String? message})> register({
    required String username,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.register(
        username: username,
        email: email,
        password: password,
        verificationCode: verificationCode,
      );
      return (success: true, message: '注册成功');
    } catch (e) {
      return (success: false, message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登录
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      developer.log('正在调用登录 API...');
      final (user, token) = await _repository.login(email, password);
      developer.log('登录 API 调用成功，获取到 token: ${token.substring(0, 10)}...');

      _currentUser = user;
      developer.log('用户信息已更新: ${user.toString()}');

      // 登录成功后检查版本
      await _checkVersion();

      return true;
    } catch (e, stackTrace) {
      developer.log(
        '登录过程发生错误',
        error: e.toString(),
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登出
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    // 清除保存的登录信息
    await _prefs.remove('saved_email');
    await _prefs.remove('saved_password');
    await _prefs.setBool('remember_me', false);
    notifyListeners();
  }
}
