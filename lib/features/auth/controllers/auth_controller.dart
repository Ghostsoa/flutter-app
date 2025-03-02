import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/logger.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  late final AuthRepository _repository;
  late final SharedPreferences _prefs;
  User? _currentUser;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthController._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _repository = await AuthRepository.create();
    await _tryAutoLogin();
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
        Logger.info('尝试使用保存的账号密码自动登录');
        // 先尝试快速登录
        final quickLoginResult = await _repository.quickLogin();

        if (quickLoginResult != null) {
          final (user, _) = quickLoginResult;
          _currentUser = user;
          Logger.info('快速登录成功');
        } else {
          // 如果快速登录失败，尝试使用账号密码登录
          Logger.info('快速登录失败，尝试使用账号密码登录');
          final (user, _) = await _repository.login(savedEmail, savedPassword);
          _currentUser = user;
          Logger.info('账号密码登录成功');
        }
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

      await _repository.sendVerificationCode(email);
      return (success: true, message: '验证码已发送');
    } catch (e) {
      final message = e.toString();
      if (message.contains('400')) {
        return (
          success: false,
          message: message.contains('message')
              ? message.split('message":"')[1].split('"')[0]
              : '邮箱格式不正确'
        );
      }
      return (success: false, message: '发送验证码失败，请稍后重试');
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

      _currentUser = await _repository.register(
        username: username,
        email: email,
        password: password,
        verificationCode: verificationCode,
      );
      return (success: true, message: '注册成功');
    } catch (e) {
      final message = e.toString();
      if (message.contains('400')) {
        return (
          success: false,
          message: message.contains('message')
              ? message.split('message":"')[1].split('"')[0]
              : '注册信息有误，请检查后重试'
        );
      }
      return (success: false, message: '注册失败，请稍后重试');
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
