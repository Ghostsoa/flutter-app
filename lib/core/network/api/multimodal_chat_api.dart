import 'package:my_app/data/models/multimodal_message.dart';
import '../dio/dio_client.dart';

class MultimodalChatApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  final DioClient _client;

  MultimodalChatApi(this._client);

  Future<MultimodalResponse> chat({
    required String message,
    required List<MultimodalMessage> history,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/api/v1/chat/multimodal',
        data: {
          'message': message,
          'history': history.map((msg) => msg.toJson()).toList(),
        },
      );

      return MultimodalResponse.fromJson(response.data['data']);
    } catch (e) {
      throw '多模态对话请求失败: $e';
    }
  }
}
