import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

class DioClient {
  static const String _tokenKey = 'auth_token';

  late final Dio _dio;
  final SharedPreferences _prefs;

  DioClient(String baseUrl, this._prefs) {
    _initDio(baseUrl);
  }

  Future<void> _initDio(String baseUrl) async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'X-Client-Version': '3.1',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _prefs.getString(_tokenKey);
        Logger.network('发送请求: ${options.uri}');
        Logger.network('请求头: ${options.headers}');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        Logger.network('收到响应: ${response.statusCode}');
        Logger.network('响应数据: ${response.data}');

        if (response.statusCode == 401) {
          _prefs.remove(_tokenKey);
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: '登录已过期，请重新登录',
          );
        }

        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.data['message'] ?? '请求失败',
          );
        }

        return handler.next(response);
      },
      onError: (error, handler) {
        Logger.error(
          '请求错误: ${error.message}',
          error: error,
          stackTrace: error.stackTrace,
        );
        return handler.next(error);
      },
    ));
  }

  void setToken(String? token) {
    if (token != null) {
      _prefs.setString(_tokenKey, token);
    } else {
      _prefs.remove(_tokenKey);
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options ??
            Options(
              responseType: path.endsWith('/stream')
                  ? ResponseType.stream
                  : ResponseType.json,
              headers: {
                if (path.endsWith('/stream')) 'Accept': 'text/event-stream',
              },
            ),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }
}
