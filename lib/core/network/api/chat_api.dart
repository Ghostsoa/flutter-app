import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../../data/models/chat_message.dart';
import '../dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class ChatApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  static const String _streamEndpoint = '/api/v1/chat/completions/stream';
  static const String _nonStreamEndpoint = '/api/v1/chat/completions';

  late final DioClient _dioClient;
  bool _initialized = false;

  ChatApi._internal();

  static final ChatApi _instance = ChatApi._internal();
  static ChatApi get instance => _instance;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      final prefs = await SharedPreferences.getInstance();
      _dioClient = DioClient(_baseUrl, prefs);
      _initialized = true;
    }
  }

  /// 构建系统提示词
  String _buildSystemPrompt(Character character, {bool includeStatus = true}) {
    final buffer = StringBuffer();

    // 添加角色基本设定
    buffer.writeln('[角色设定]');
    buffer.writeln(character.description);
    buffer.writeln();

    // 添加用户自定义设定
    if (character.userSetting?.isNotEmpty == true) {
      buffer.writeln('[用户设定]');
      buffer.writeln(character.userSetting);
      buffer.writeln();
    }

    // 添加状态信息
    if (includeStatus &&
        character.hasStatus &&
        character.statusList.isNotEmpty) {
      buffer.writeln('最后结尾请用[]包裹状态');

      // 构建状态字符串
      final statusParts = character.statusList.map((status) {
        if (status.type == 'number') {
          return '${status.name}:${status.numberValue}';
        } else {
          return '${status.name}:${status.value}';
        }
      }).join(',');

      buffer.writeln('[$statusParts]');
    }

    return buffer.toString();
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequestBody({
    required String model,
    required List<Map<String, String>> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
  }) {
    return {
      'model': model,
      'messages': messages,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (presencePenalty != null) 'presence_penalty': presencePenalty,
      if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
    };
  }

  /// 将文本按标点符号分段
  List<String> _splitTextByPunctuation(String text) {
    final segments = <String>[];
    var currentSegment = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      currentSegment.write(text[i]);

      // 检查是否遇到标点符号
      if ('。！？!?'.contains(text[i]) ||
          (i == text.length - 1 && currentSegment.isNotEmpty)) {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment.toString());
          currentSegment.clear();
        }
      }
    }

    // 处理剩余的文本
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment.toString());
    }

    return segments;
  }

  /// 发送非流式请求
  Stream<String> sendChatRequest({
    required Character character,
    required ModelConfig modelConfig,
    required List<Map<String, String>> messages,
  }) async* {
    await _ensureInitialized();

    try {
      final fullMessages = [
        {
          'role': 'system',
          'content': _buildSystemPrompt(character,
              includeStatus: !modelConfig.chunkResponse)
        },
        ...messages,
      ];

      final body = _buildRequestBody(
        model: modelConfig.model,
        messages: fullMessages,
        temperature: modelConfig.temperature,
        topP: modelConfig.topP,
        maxTokens: modelConfig.maxTokens,
        presencePenalty: modelConfig.presencePenalty,
        frequencyPenalty: modelConfig.frequencyPenalty,
      );

      final response = await _dioClient.post(
        _nonStreamEndpoint,
        data: body,
      );

      final responseData = response.data as Map<String, dynamic>;
      final choices = responseData['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw Exception('服务器返回的响应格式错误');
      }
      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'] as String;

      // 根据配置决定是否分段返回
      if (modelConfig.chunkResponse && !modelConfig.streamResponse) {
        // 分段返回模式，每句话都作为独立的消息返回
        final segments = _splitTextByPunctuation(content);
        for (final segment in segments) {
          if (segment.trim().isNotEmpty) {
            yield '[MESSAGE]$segment'; // 使用特殊标记表示这是一个新消息
          }
        }
      } else {
        // 非分段模式，检查是否包含状态信息
        if (!modelConfig.streamResponse) {
          // 提取状态信息
          final (cleanContent, statusInfo) =
              ChatMessage.extractStatusInfo(content);
          if (statusInfo != null) {
            // 返回带有状态信息的消息
            yield '[STATUS]$statusInfo[CONTENT]$cleanContent';
          } else {
            yield content;
          }
        } else {
          // 流式模式直接返回内容
          yield content;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 发送流式请求
  Stream<String> sendStreamChatRequest({
    required Character character,
    required ModelConfig modelConfig,
    required List<Map<String, String>> messages,
  }) async* {
    await _ensureInitialized();

    try {
      final fullMessages = [
        {
          'role': 'system',
          'content': _buildSystemPrompt(character, includeStatus: false)
        },
        ...messages,
      ];

      final body = _buildRequestBody(
        model: modelConfig.model,
        messages: fullMessages,
        temperature: modelConfig.temperature,
        topP: modelConfig.topP,
        maxTokens: modelConfig.maxTokens,
        presencePenalty: modelConfig.presencePenalty,
        frequencyPenalty: modelConfig.frequencyPenalty,
      );

      final response = await _dioClient.post(
        _streamEndpoint,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = (response.data as ResponseBody).stream;
      String buffer = '';

      await for (final chunk in stream) {
        final chunkText = utf8.decode(chunk);
        buffer += chunkText;

        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isEmpty) continue;
          if (!line.startsWith('data: ')) continue;

          final data = line.substring(6);
          if (data == '[DONE]') {
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['object'] != 'chat.completion.chunk') continue;

            final choices = json['choices'] as List<dynamic>;
            if (choices.isEmpty) continue;

            final delta = (choices[0] as Map<String, dynamic>)['delta']
                as Map<String, dynamic>;
            final content = delta['content'] as String?;
            if (content != null) {
              yield content;
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
