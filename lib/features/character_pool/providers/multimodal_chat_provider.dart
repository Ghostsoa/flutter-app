import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:my_app/core/network/api/multimodal_chat_api.dart';
import 'package:my_app/data/models/multimodal_message.dart';

class MultimodalChatProvider extends ChangeNotifier {
  final MultimodalChatApi _api;
  final SharedPreferences _prefs;
  static const String _storageKey = 'multimodal_chat_history';
  static const int _maxHistoryRounds = 3;

  List<MultimodalMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  MultimodalChatProvider(this._api, this._prefs) {
    _loadHistory();
  }

  List<MultimodalMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadHistory() async {
    try {
      final historyJson = _prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _messages =
            decoded.map((item) => MultimodalMessage.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = '加载历史记录失败: $e';
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    try {
      final historyJson = json.encode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, historyJson);
    } catch (e) {
      _error = '保存历史记录失败: $e';
      notifyListeners();
    }
  }

  List<MultimodalMessage> _getHistoryForApi() {
    final historyLength = _messages.length;
    if (historyLength <= _maxHistoryRounds * 2) {
      return _messages;
    }
    return _messages.sublist(historyLength - _maxHistoryRounds * 2);
  }

  Future<void> sendMessage({
    required String text,
    String? imageBase64,
    String imageMimeType = 'image/jpeg',
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      // 添加用户消息
      final userMessage = MultimodalMessage.createUserMessage(
        text: text,
        imageBase64: imageBase64,
        imageMimeType: imageMimeType,
      );
      _messages.add(userMessage);
      notifyListeners();

      // 调用API
      final response = await _api.chat(
        message: text,
        history: _getHistoryForApi(),
      );

      // 添加AI响应
      final aiMessage = MultimodalMessage.createModelMessage(
        text: response.text,
        generatedImageBase64: response.imageData,
      );
      _messages.add(aiMessage);

      // 保存历史记录
      await _saveHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    _prefs.remove(_storageKey);
    notifyListeners();
  }
}
