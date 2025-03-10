import '../dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

class VersionInfo {
  final double minVersion;
  final double latestVersion;

  VersionInfo({
    required this.minVersion,
    required this.latestVersion,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      minVersion: _parseVersion(json['min_version']),
      latestVersion: _parseVersion(json['latest_version']),
    );
  }

  static double _parseVersion(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Invalid version format: $value');
  }
}

class VersionApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  late final DioClient _client;

  VersionApi();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _client = DioClient(_baseUrl, prefs);
  }

  Future<VersionInfo> getVersion() async {
    try {
      final response = await _client.get('/api/v1/version');
      final data = response.data;

      if (data['code'] != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? '获取版本号失败');
      }

      return VersionInfo.fromJson(data['data']);
    } catch (e) {
      Logger.error('获取版本号失败', error: e);
      rethrow;
    }
  }
}
