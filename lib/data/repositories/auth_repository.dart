import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio/dio_client.dart';
import '../../core/network/api/auth_api.dart';
import '../../core/utils/logger.dart';
import '../local/shared_prefs/auth_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final DioClient _dioClient;
  final AuthStorage _authStorage;

  AuthRepository._internal(this._dioClient, this._authStorage);

  static Future<AuthRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final dioClient = DioClient(AuthApi.baseUrl, prefs);
    final authStorage = AuthStorage(prefs);
    return AuthRepository._internal(dioClient, authStorage);
  }

  // 发送验证码
  Future<void> sendVerificationCode(String email) async {
    await _dioClient.post(AuthApi.registerCode, data: {
      'email': email,
    });
  }

  // 注册
  Future<User> register({
    required String username,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    final response = await _dioClient.post(AuthApi.register, data: {
      'username': username,
      'email': email,
      'password': password,
      'code': verificationCode,
    });

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  // 登录
  Future<(User, String)> login(String email, String password) async {
    try {
      Logger.network('准备发送登录请求');
      Logger.network('API地址: ${AuthApi.login}');
      Logger.network('请求参数: email=$email');

      final response = await _dioClient.post(AuthApi.login, data: {
        'email': email,
        'password': password,
      });

      Logger.network('收到登录响应');
      Logger.network('状态码: ${response.statusCode}');
      Logger.network('响应数据: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user']);
      final token = data['token'] as String;

      Logger.info('Token 已保存到本地存储');
      await _authStorage.saveToken(token);
      _dioClient.setToken(token);

      return (user, token);
    } catch (e, stackTrace) {
      Logger.error(
        '登录请求失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // 快速登录
  Future<(User, String)?> quickLogin() async {
    final token = await _authStorage.getToken();
    if (token == null) return null;

    try {
      final response = await _dioClient.post(
        AuthApi.quickLogin,
        data: {'credential': token},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user']);
      final newToken = data['token'] as String;

      await _authStorage.saveToken(newToken);
      _dioClient.setToken(newToken);
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
