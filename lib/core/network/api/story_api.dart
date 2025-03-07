import 'dart:convert';
import '../../../data/models/story_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio/dio_client.dart';
import 'package:flutter/foundation.dart';

class StoryApi {
  static const String _baseUrl = 'https://cc.xiaoyi.live';
  late final DioClient _client;

  StoryApi();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _client = DioClient(_baseUrl, prefs);
  }

  Future<String> chat(List<StoryMessage> messages) async {
    try {
      final response = await _client.post(
        '/api/v1/chat/completions',
        data: {
          'model': 'gemini-2.0-flash-exp',
          'messages': messages
              .map((m) => {
                    'role': m.role.name,
                    'content': m.content,
                  })
              .toList(),
          'temperature': 0.7,
          'top_p': 0.95,
          'max_tokens': 2000,
        },
      );

      if (response.statusCode == 200) {
        final json = response.data;
        if (json['choices'] != null &&
            json['choices'].isNotEmpty &&
            json['choices'][0]['message'] != null &&
            json['choices'][0]['message']['content'] != null) {
          String content = json['choices'][0]['message']['content'] as String;
          debugPrint('原始响应内容: $content');

          // 处理内容中的 JSON
          try {
            if (content.contains('```json')) {
              // 如果内容被 ```json 包裹，提取 JSON 字符串
              final start = content.indexOf('```json') + 7;
              final end = content.lastIndexOf('```');
              if (end > start) {
                content = content.substring(start, end).trim();
                debugPrint('提取的 JSON 内容: $content');
              }
            }

            // 尝试修复和解析 JSON
            try {
              // 先尝试直接解析
              final jsonData = jsonDecode(content);
              if (_isValidJson(jsonData)) {
                return jsonEncode(jsonData);
              }
            } catch (e) {
              debugPrint('直接解析失败，尝试修复: $e');
            }

            // 如果直接解析失败，尝试修复
            if (content.endsWith('}}}')) {
              // 检查是否有未闭合的对象
              final openBraces = content.split('{').length - 1;
              final closeBraces = content.split('}').length - 1;
              if (openBraces > closeBraces) {
                content =
                    content + List.filled(openBraces - closeBraces, '}').join();
              }
            }

            // 再次尝试解析
            final jsonData = jsonDecode(content);
            if (!_isValidJson(jsonData)) {
              throw Exception('JSON 结构不完整');
            }
            debugPrint('成功修复并解析 JSON');
            return jsonEncode(jsonData);
          } catch (e) {
            debugPrint('JSON 解析失败: $e');
            rethrow; // 让调用方进行重试
          }
        } else {
          debugPrint('无效的响应格式: ${json.toString()}');
          throw Exception('无效的响应格式');
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API请求错误: $e');
      rethrow;
    }
  }

  Future<String> distill(List<StoryMessage> messages) async {
    try {
      final response = await _client.post(
        '/api/v1/chat/completions',
        data: {
          'model': 'gemini-2.0-flash-exp',
          'messages': messages
              .map((m) => {
                    'role': m.role.name,
                    'content': m.content,
                  })
              .toList(),
          'temperature': 0.3, // 降低温度，使输出更加稳定和连贯
          'top_p': 0.8, // 适度降低采样范围
          'max_tokens': 8196, // 适中的长度限制，足够总结但不会过长
          'presence_penalty': 0.1, // 轻微的重复惩罚
          'frequency_penalty': 0.2, // 适度的频率惩罚，避免重复内容
        },
      );

      if (response.statusCode == 200) {
        final json = response.data;
        if (json['choices'] != null &&
            json['choices'].isNotEmpty &&
            json['choices'][0]['message'] != null &&
            json['choices'][0]['message']['content'] != null) {
          return json['choices'][0]['message']['content'] as String;
        }
      }
      throw Exception('API请求失败');
    } catch (e) {
      debugPrint('蒸馏API请求错误: $e');
      rethrow;
    }
  }

  bool _isValidJson(Map<String, dynamic> json) {
    // 检查必需的顶级字段
    if (json['content'] == null ||
        json['status_updates'] == null ||
        json['next_actions'] == null) {
      return false;
    }

    // 检查 status_updates 是否是 Map
    final statusUpdates = json['status_updates'];
    if (statusUpdates is! Map) {
      return false;
    }

    // 检查 next_actions 是否是 List
    if (json['next_actions'] is! List) {
      return false;
    }

    // 检查 character 字段是否存在
    final character = statusUpdates['character'];
    if (character == null || character is! Map) {
      return false;
    }

    // 不再强制要求 basic_status 必须存在或包含特定字段
    return true;
  }
}
