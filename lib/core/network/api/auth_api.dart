import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/user.dart';

class AuthApi {
  static const String baseUrl = 'https://cc.xiaoyi.live';

  // 认证相关接口
  static const String registerPath = '/api/v1/register';
  static const String registerCodePath = '/api/v1/register/code';
  static const String loginPath = '/api/v1/login';
  static const String quickLoginPath = '/api/v1/quick-login';

  final Dio _dio;

  AuthApi._()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'X-Client-Version': '3.2',
            'Content-Type': 'application/json',
          },
          validateStatus: (_) => true,
        ));

  static final AuthApi _instance = AuthApi._();
  static AuthApi get instance => _instance;

  // 发送验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      Logger.network('发送验证码请求: $registerCodePath');
      Logger.network('请求参数: email=$email');

      final response = await _dio.post(
        registerCodePath,
        data: {'email': email},
        options: Options(validateStatus: (_) => true),
      );

      Logger.network('收到响应: ${response.statusCode}');
      Logger.network('响应数据: ${response.data}');

      final responseData = response.data;
      if (responseData['code'] != 200) {
        throw responseData['message'] ?? '发送验证码失败';
      }

      return responseData;
    } catch (e) {
      Logger.error('发送验证码失败', error: e);
      rethrow;
    }
  }

  // 注册
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    try {
      Logger.network('发送注册请求: $registerPath');

      final response = await _dio.post(
        registerPath,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'code': verificationCode,
        },
        options: Options(validateStatus: (_) => true),
      );

      Logger.network('响应数据: ${response.data}');
      final responseData = response.data;

      // 只验证状态码是否为 200
      if (responseData['code'] == 200) {
        return;
      }

      // 失败时抛出具体错误信息
      throw responseData['message'] ?? '注册失败';
    } catch (e) {
      Logger.error('注册失败', error: e);
      rethrow;
    }
  }

  // 登录
  Future<(User, String)> login(String email, String password) async {
    try {
      Logger.network('发送登录请求: $loginPath');

      final response = await _dio.post(
        loginPath,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(validateStatus: (_) => true),
      );

      final responseData = response.data;
      if (responseData['code'] != 200) {
        throw responseData['message'] ?? '登录失败';
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user']);
      final token = data['token'] as String;

      return (user, token);
    } catch (e) {
      Logger.error('登录失败', error: e);
      rethrow;
    }
  }

  // 快速登录
  Future<(User, String)> quickLogin(String credential) async {
    try {
      Logger.network('发送快速登录请求: $quickLoginPath');

      final response = await _dio.post(
        quickLoginPath,
        data: {'credential': credential},
        options: Options(validateStatus: (_) => true),
      );

      final responseData = response.data;
      if (responseData['code'] != 200) {
        throw responseData['message'] ?? '快速登录失败';
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user']);
      final token = data['token'] as String;

      return (user, token);
    } catch (e) {
      Logger.error('快速登录失败', error: e);
      rethrow;
    }
  }
}
