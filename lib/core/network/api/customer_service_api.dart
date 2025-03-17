import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio/dio_client.dart';

class CustomerServiceApi {
  static CustomerServiceApi? _instance;
  final DioClient _dioClient;

  CustomerServiceApi._(this._dioClient);

  static Future<CustomerServiceApi> getInstance() async {
    if (_instance != null) return _instance!;

    final prefs = await SharedPreferences.getInstance();
    final dioClient = DioClient('https://cc.xiaoyi.live', prefs);
    _instance = CustomerServiceApi._(dioClient);
    return _instance!;
  }

  Stream<String> chat(String content) async* {
    final response = await _dioClient.post(
      '/api/v1/customer/chat',
      data: {'content': content},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    const utf8Decoder = Utf8Decoder();
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8Decoder.convert(chunk);

      while (buffer.contains('\n')) {
        final index = buffer.indexOf('\n');
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);

        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null && content.isNotEmpty) {
                final trimmedContent = content.trim();
                if (trimmedContent.isNotEmpty) {
                  yield trimmedContent;
                }
              }
            }
          } catch (e) {
            print('JSON解析错误: $e, 原始数据: $data');
          }
        }
      }
    }
  }
}
