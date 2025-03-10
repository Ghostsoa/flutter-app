import '../dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

class CardKeyRedeemException implements Exception {
  final String message;
  CardKeyRedeemException(this.message);

  @override
  String toString() => message;
}

class CardKeyApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  late final DioClient _client;

  CardKeyApi();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _client = DioClient(_baseUrl, prefs);
  }

  Future<void> redeemCardKey(String key) async {
    try {
      final response = await _client.post(
        '/api/v1/card-keys/redeem',
        data: {'key': key},
      );

      final data = response.data;
      if (data['code'] != 200 || data['success'] != true) {
        throw CardKeyRedeemException(data['message'] ?? '兑换失败');
      }
    } catch (e) {
      if (e is CardKeyRedeemException) {
        rethrow;
      }
      Logger.error('卡密兑换失败', error: e);
      throw CardKeyRedeemException('网络错误，请稍后重试');
    }
  }
}
