import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  late final AuthRepository _repository;
  User? _currentUser;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthController._internal();

  Future<void> init() async {
    _repository = await AuthRepository.create();
    await _tryQuickLogin();
  }

  Future<void> _tryQuickLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _repository.quickLogin();
      if (result != null) {
        final (user, _) = result;
        _currentUser = user;
      }
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
    notifyListeners();
  }
}
