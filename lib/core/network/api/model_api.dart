import '../dio/dio_client.dart';
import '../../../data/models/model_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  late final DioClient _dioClient;
  bool _initialized = false;

  ModelApi._internal();

  static final ModelApi _instance = ModelApi._internal();
  static ModelApi get instance => _instance;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      final prefs = await SharedPreferences.getInstance();
      _dioClient = DioClient(_baseUrl, prefs);
      _initialized = true;
    }
  }

  /// 获取可用的模型列表
  Future<List<ModelInfo>> getModels() async {
    await _ensureInitialized();

    try {
      final response = await _dioClient.get('/api/v1/models');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List<dynamic>;
      return data.map((json) => ModelInfo.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
