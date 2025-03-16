import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api/auth_api.dart';
import '../../core/utils/logger.dart';
import '../local/shared_prefs/auth_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final AuthStorage _authStorage;

  AuthRepository._internal(this._authStorage);

  static Future<AuthRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final authStorage = AuthStorage(prefs);
    return AuthRepository._internal(authStorage);
  }

  // 发送验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return AuthApi.instance.sendVerificationCode(email);
  }

  // 注册
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    return AuthApi.instance.register(
      username: username,
      email: email,
      password: password,
      verificationCode: verificationCode,
    );
  }

  // 登录
  Future<(User, String)> login(String email, String password) async {
    try {
      Logger.info('尝试登录');
      final (user, token) = await AuthApi.instance.login(email, password);

      Logger.info('登录成功，保存 token');
      await _authStorage.saveToken(token);

      return (user, token);
    } catch (e) {
      Logger.error('登录失败', error: e);
      rethrow;
    }
  }

  // 快速登录
  Future<(User, String)?> quickLogin() async {
    final savedToken = await _authStorage.getToken();
    if (savedToken == null) return null;

    try {
      final (user, newToken) = await AuthApi.instance.quickLogin(savedToken);
      await _authStorage.saveToken(newToken);
      return (user, newToken);
    } catch (e) {
      await _authStorage.clearToken();
      return null;
    }
  }

  // 登出
  Future<void> logout() async {
    await _authStorage.clearToken();
  }
}
