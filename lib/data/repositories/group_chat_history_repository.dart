import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/group_chat_message.dart';
import '../../core/utils/logger.dart';

/// UI消息记录仓库
class GroupChatMessageRepository {
  static const String _messageDir = 'group_chat_messages';
  static GroupChatMessageRepository? _instance;
  late final Directory _baseDir;

  GroupChatMessageRepository._();

  static Future<GroupChatMessageRepository> create() async {
    if (_instance != null) return _instance!;

    final repository = GroupChatMessageRepository._();
    await repository._init();
    _instance = repository;
    return repository;
  }

  Future<void> _init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(path.join(appDir.path, _messageDir));
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }
  }

  String _getMessagePath(String groupId) {
    return path.join(_baseDir.path, '$groupId.json');
  }

  /// 保存消息列表
  Future<void> saveMessages(
      String groupId, List<GroupChatMessage> messages) async {
    try {
      final file = File(_getMessagePath(groupId));
      final data = messages.map((m) => m.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      Logger.error('保存消息列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取消息列表
  Future<List<GroupChatMessage>> getMessages(String groupId) async {
    try {
      final file = File(_getMessagePath(groupId));
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.map((json) => GroupChatMessage.fromJson(json)).toList();
    } catch (e, stackTrace) {
      Logger.error('获取消息列表失败', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// 添加新消息
  Future<void> addMessage(GroupChatMessage message) async {
    try {
      final messages = await getMessages(message.groupId);
      messages.add(message);
      await saveMessages(message.groupId, messages);
    } catch (e, stackTrace) {
      Logger.error('添加消息失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 清空消息
  Future<void> clearMessages(String groupId) async {
    try {
      await saveMessages(groupId, []);
    } catch (e, stackTrace) {
      Logger.error('清空消息失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 删除消息记录
  Future<void> deleteMessages(String groupId) async {
    try {
      final file = File(_getMessagePath(groupId));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      Logger.error('删除消息记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 移除最后一条消息
  Future<void> removeLastMessage(String groupId) async {
    try {
      final messages = await getMessages(groupId);
      if (messages.isNotEmpty) {
        messages.removeLast();
        await saveMessages(groupId, messages);
      }
    } catch (e, stackTrace) {
      Logger.error('移除最后一条消息失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 请求历史记录仓库
class GroupChatHistoryRepository {
  static const String _historyDir = 'group_chat_history';
  static GroupChatHistoryRepository? _instance;
  late final Directory _baseDir;

  GroupChatHistoryRepository._();

  static Future<GroupChatHistoryRepository> create() async {
    if (_instance != null) return _instance!;

    final repository = GroupChatHistoryRepository._();
    await repository._init();
    _instance = repository;
    return repository;
  }

  Future<void> _init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(path.join(appDir.path, _historyDir));
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }
  }

  String _getHistoryPath(String groupId) {
    return path.join(_baseDir.path, '$groupId.xml');
  }

  /// 获取XML历史记录
  Future<String> getHistory(String groupId) async {
    try {
      final file = File(_getHistoryPath(groupId));
      if (!await file.exists()) {
        return '';
      }
      return await file.readAsString();
    } catch (e, stackTrace) {
      Logger.error('获取历史记录失败', error: e, stackTrace: stackTrace);
      return '';
    }
  }

  /// 保存XML历史记录
  Future<void> saveHistory(String groupId, String xmlHistory) async {
    try {
      final file = File(_getHistoryPath(groupId));
      await file.writeAsString(xmlHistory);
    } catch (e, stackTrace) {
      Logger.error('保存历史记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 添加新消息到历史记录
  Future<void> appendHistory(
      String groupId, String role, String content) async {
    try {
      final history = await getHistory(groupId);
      final xmlMessage = '\n<msg role="$role">$content</msg>';
      await saveHistory(groupId, history + xmlMessage);
    } catch (e, stackTrace) {
      Logger.error('添加历史记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 清空历史记录
  Future<void> clearHistory(String groupId) async {
    try {
      await saveHistory(groupId, '');
    } catch (e, stackTrace) {
      Logger.error('清空历史记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 删除历史记录
  Future<void> deleteHistory(String groupId) async {
    try {
      final file = File(_getHistoryPath(groupId));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      Logger.error('删除历史记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 移除最后一条消息
  Future<void> removeLastMessage(String groupId) async {
    try {
      final history = await getHistory(groupId);
      final lastMessageStart = history.lastIndexOf('<msg');
      if (lastMessageStart >= 0) {
        final newHistory = history.substring(0, lastMessageStart).trimRight();
        await saveHistory(groupId, newHistory);
      }
    } catch (e, stackTrace) {
      Logger.error('移除最后一条历史记录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
