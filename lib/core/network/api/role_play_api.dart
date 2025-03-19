import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio/dio_client.dart';
import '../../../data/models/character.dart';
import '../../../data/models/group_chat.dart';
import '../../../data/models/story.dart';
import '../../../data/models/hall_item.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RolePlayApi {
  static RolePlayApi? _instance;
  final DioClient _dioClient;

  RolePlayApi._(this._dioClient);

  static Future<RolePlayApi> getInstance() async {
    if (_instance != null) return _instance!;

    final prefs = await SharedPreferences.getInstance();
    final dioClient = DioClient('https://cc.xiaoyi.live', prefs);
    _instance = RolePlayApi._(dioClient);
    return _instance!;
  }

  Future<Map<String, dynamic>> uploadCharacter(
      Character character, String description) async {
    try {
      final characterData = {
        "name": character.name,
        "description": character.description,
        "coverImageData": character.coverImageUrl != null
            ? base64Encode(await File(character.coverImageUrl!).readAsBytes())
            : null,
        "userSetting": character.userSetting,
        "greeting": character.greeting,
        "useMarkdown": character.useMarkdown,
        "hasStatus": character.hasStatus,
        "statusList": character.statusList.map((s) => s.toJson()).toList(),
        "style": {
          "backgroundOpacity": character.backgroundOpacity,
          "userBubbleColor": character.userBubbleColor,
          "aiBubbleColor": character.aiBubbleColor,
          "userTextColor": character.userTextColor,
          "aiTextColor": character.aiTextColor,
        },
        "modelConfig": {
          "model": character.model,
          "useAdvancedSettings": character.useAdvancedSettings,
          "temperature": character.temperature,
          "topP": character.topP,
          "presencePenalty": character.presencePenalty,
          "frequencyPenalty": character.frequencyPenalty,
          "maxTokens": character.maxTokens,
          "streamResponse": character.streamResponse,
          "enableDistillation": character.enableDistillation,
          "distillationRounds": character.distillationRounds,
          "distillationModel": character.distillationModel,
        }
      };

      final requestData = {
        "type": "character",
        "description": description,
        "data": characterData
      };

      final response = await _dioClient.post(
        '/api/v1/role-play',
        data: requestData,
      );

      if (response.statusCode == 500) {
        final errorMessage = response.data['message'] ?? '服务器内部错误';
        throw errorMessage;
      }

      debugPrint('RolePlayApi uploadCharacter response: ${response.data}');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        throw '无效的响应数据格式';
      }

      return response.data;
    } catch (e) {
      debugPrint('RolePlayApi uploadCharacter error: $e');
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '上传失败';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadGroupChat(
      GroupChat group, String description) async {
    try {
      final groupData = {
        "name": group.name,
        "setting": group.setting,
        "greeting": group.greeting,
        "backgroundImageData": group.backgroundImageData,
        "showDecisionProcess": group.showDecisionProcess,
        "streamResponse": group.streamResponse,
        "enableDistillation": group.enableDistillation,
        "distillationRounds": group.distillationRounds,
        "roles": group.roles
            .map((role) => {
                  "name": role.name,
                  "description": role.description,
                  "avatarData": role.avatarUrl,
                  "modelConfig": {
                    "model": role.model,
                    "useAdvancedSettings": role.useAdvancedSettings,
                    "temperature": role.temperature,
                    "topP": role.topP,
                    "presencePenalty": role.presencePenalty,
                    "frequencyPenalty": role.frequencyPenalty,
                    "maxTokens": role.maxTokens
                  }
                })
            .toList(),
      };

      final requestData = {
        "type": "group_chat",
        "description": description,
        "data": groupData
      };

      final response = await _dioClient.post(
        '/api/v1/role-play',
        data: requestData,
      );

      if (response.statusCode == 500) {
        final errorMessage = response.data['message'] ?? '服务器内部错误';
        throw errorMessage;
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '上传失败';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadStory(Story story) async {
    try {
      // 获取完整的导出数据（包含 base64 编码的图片）
      final storyData = await story.toExportJson();

      final requestData = {
        "version": "1.0",
        "type": "story",
        "data": storyData,
      };

      final response = await _dioClient.post(
        '/api/v1/role-play',
        data: requestData,
      );

      if (response.statusCode == 500) {
        final errorMessage = response.data['message'] ?? '服务器内部错误';
        throw errorMessage;
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '上传失败';
      }
      rethrow;
    }
  }

  Future<HallResponse> getHallItems({
    required int page,
    required int pageSize,
    String? type,
    String? query,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'page_size': pageSize,
        if (type != null) 'type': type,
        if (query != null) 'keyword': query,
      };

      final response = await _dioClient.get(
        '/api/v1/role-play',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 500) {
        final errorMessage = response.data['message'] ?? '服务器内部错误';
        throw errorMessage;
      }

      return HallResponse.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '获取失败';
      }
      rethrow;
    }
  }

  Future<HallResponse> getMyItems({
    required int page,
    required int pageSize,
    String? type,
    String? query,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'page_size': pageSize,
        if (type != null) 'type': type,
        if (query != null) 'keyword': query,
      };

      final response = await _dioClient.get(
        '/api/v1/role-play/my',
        queryParameters: queryParameters,
      );

      return HallResponse.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '获取失败';
      }
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dioClient.delete('/api/v1/role-play/$id');
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '删除失败';
      }
      rethrow;
    }
  }

  Future<Uint8List> getImageBytes(String imageUrl) async {
    try {
      final response = await _dioClient.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data['message'] ?? e.message;
          throw errorMessage;
        }
        throw e.message ?? '获取图片失败';
      }
      rethrow;
    }
  }
}
